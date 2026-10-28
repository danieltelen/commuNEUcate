import { supabase } from '../backend.js';

const $ = (selector, root = document) => root.querySelector(selector);
const $$ = (selector, root = document) => [...root.querySelectorAll(selector)];
const esc = value => String(value ?? '').replace(/[&<>"']/g, char => ({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[char]));
let adminUser = null;
let currentView = 'dashboard';
let pendingRejectId = null;
let profilesCache = [];
let reportCache = [];
let toastTimer;

function toast(message, error = false) {
  const node = $('#admin-toast'); node.textContent = message; node.classList.toggle('error',error); node.classList.add('show');
  clearTimeout(toastTimer); toastTimer = setTimeout(() => node.classList.remove('show'),3300);
}

function showPortal(isAdmin) {
  $('#admin-login').classList.toggle('hidden',isAdmin);
  $('#admin-app').classList.toggle('hidden',!isAdmin);
  if (isAdmin) { $('#admin-email').textContent = adminUser.email || ''; renderView(currentView); }
}

async function verifyAndEnter(session) {
  if (!session?.user) { adminUser = null; showPortal(false); return; }
  const {data,error} = await supabase.from('profiles').select('role,account_status').eq('id',session.user.id).maybeSingle();
  if (error || data?.role !== 'admin') {
    await supabase.auth.signOut();
    $('#admin-login-message').textContent = data ? 'This account does not have administrator access.' : 'Admin profile not found. Ask an existing admin to grant access.';
    showPortal(false); return;
  }
  adminUser = session.user; showPortal(true);
}

function setActiveView(view) {
  currentView = view;
  $$('.admin-nav,.admin-mobile-nav button').forEach(button => button.classList.toggle('active',button.dataset.view === view));
  $('#admin-page-title').textContent = ({dashboard:'Dashboard',reports:'Report approvals',users:'Manage users'})[view];
}

async function fetchAdminData() {
  const [profilesResult,reportsResult,claimsResult] = await Promise.all([
    supabase.from('profiles').select('id,email,full_name,role,account_status,created_at').order('created_at',{ascending:false}),
    supabase.from('reports').select('*').order('created_at',{ascending:false}),
    supabase.from('claims').select('id,report_id,status').eq('status','pending'),
  ]);
  const error = profilesResult.error || reportsResult.error || claimsResult.error;
  if (error) throw error;
  profilesCache = profilesResult.data || [];
  reportCache = reportsResult.data || [];
  const claimIds = new Set((claimsResult.data || []).map(claim => String(claim.report_id)));
  const reviewQueue = reportCache.filter(report => report.status === 'pending_review' && !claimIds.has(String(report.id)));
  return {profiles:profilesCache,reports:reportCache,reviewQueue,claims:claimIds};
}

async function renderView(view) {
  if (!adminUser) return;
  setActiveView(view);
  const content = $('#admin-content'); content.innerHTML = '<div class="admin-empty"><span class="spinner"></span></div>';
  try {
    const data = await fetchAdminData();
    if (view === 'dashboard') renderDashboard(data);
    else if (view === 'reports') renderReports(data.reviewQueue,data.profiles);
    else if (view === 'users') renderUsers(data.profiles);
  } catch (error) {
    console.error('Admin data load failed:',error);
    content.innerHTML = `<div class="admin-empty">Could not load admin data.<br /><small>${esc(error.message)}</small></div>`;
  }
}

function renderDashboard({profiles,reports,reviewQueue}) {
  const pendingUsers = profiles.filter(user => user.account_status === 'pending').length;
  const approvedUsers = profiles.filter(user => user.account_status === 'approved').length;
  const revalidations = reviewQueue.filter(report => (report.revalidation_count || 0) > 0).length;
  const content = $('#admin-content');
  const preview = reviewQueue.slice(0,4);
  content.innerHTML = `<div class="admin-page-heading"><div><h1>Admin Dashboard</h1><p>Review submissions and manage access for the NEU community.</p></div></div>
    <div class="admin-stats"><article class="surface-card admin-stat"><strong>${reviewQueue.length}</strong><span>Reports awaiting approval</span></article><article class="surface-card admin-stat"><strong>${revalidations}</strong><span>Revalidations to review</span></article><article class="surface-card admin-stat"><strong>${pendingUsers}</strong><span>Users awaiting approval</span></article><article class="surface-card admin-stat"><strong>${approvedUsers}</strong><span>Approved users · ${profiles.length} total</span></article></div>
    <div class="admin-section-head"><h2>Latest in approval queue</h2><button class="admin-refresh" data-goto="reports">View queue</button></div>
    <div class="admin-queue-list">${preview.length ? preview.map(report => reportCard(report,profiles)).join('') : '<div class="surface-card admin-empty">No reports are waiting for approval.</div>'}</div>`;
  $$('[data-goto="reports"]',content).forEach(button => button.addEventListener('click',() => renderView('reports')));
  bindReportActions(content);
}

function reportCard(report,profiles) {
  const reporter = profiles.find(profile => profile.id === report.reporter_id);
  const revalidation = (report.revalidation_count || 0) > 0;
  return `<article class="surface-card admin-report-card"><div>${report.image_url ? `<img src="${esc(report.image_url)}" alt="${esc(report.item_name)}" />` : '<div class="admin-report-placeholder">▧</div>'}</div><div class="admin-report-info"><div class="admin-report-top"><span class="queue-tag${revalidation?' revalidation':''}">${revalidation?'Revalidation':'New report'}</span><span class="admin-report-top-note">${esc(report.category || '')}</span></div><h3>${esc(report.item_name)}</h3><p>Reporter: ${esc(reporter?.full_name || reporter?.email || 'Unknown')} ${reporter?.email ? `· ${esc(reporter.email)}` : ''}</p><p>Found at ${esc(report.location_found || 'Unknown')} · ${esc(report.date_found || '')}</p><p>${esc(report.description || '')}</p>${report.review_note ? `<p>Previous note: ${esc(report.review_note)}</p>` : ''}<div class="admin-report-actions"><button class="approve-button" data-approve="${esc(report.id)}">Approve and publish</button><button class="reject-button" data-reject="${esc(report.id)}">Reject with note</button></div></div></article>`;
}

function renderReports(queue,profiles) {
  const content = $('#admin-content');
  content.innerHTML = `<div class="admin-page-heading"><div><h1>Report approvals</h1><p>Approve an item to publish it to the public user web and mobile app.</p></div></div><div class="admin-queue-list">${queue.length ? queue.map(report => reportCard(report,profiles)).join('') : '<div class="surface-card admin-empty">No found-item reports are awaiting approval.</div>'}</div>`;
  bindReportActions(content);
}

function bindReportActions(root) {
  $$('[data-approve]',root).forEach(button => button.addEventListener('click',() => approveReport(button.dataset.approve,button)));
  $$('[data-reject]',root).forEach(button => button.addEventListener('click',() => {
    pendingRejectId = button.dataset.reject; $('#reject-form').reset(); $('#reject-dialog').showModal();
  }));
}

async function approveReport(id,button) {
  button.disabled = true;
  const {data,error} = await supabase.from('reports').update({status:'unclaimed',review_note:null,reviewed_at:new Date().toISOString(),reviewed_by:adminUser.id})
    .eq('id',id).eq('status','pending_review').select('id').maybeSingle();
  if (error || !data) { toast(error?.message || 'This report has already changed.',true); button.disabled = false; return; }
  toast('Report approved and published.'); renderView(currentView);
}

$('#reject-form').addEventListener('submit',async event => {
  event.preventDefault();
  const note = String(new FormData(event.currentTarget).get('review_note') || '').trim();
  if (!note || !pendingRejectId) return;
  const button = $('button[type="submit"]',event.currentTarget); button.disabled = true;
  const {data,error} = await supabase.from('reports').update({status:'rejected',review_note:note,reviewed_at:new Date().toISOString(),reviewed_by:adminUser.id})
    .eq('id',pendingRejectId).eq('status','pending_review').select('id').maybeSingle();
  button.disabled = false;
  if (error || !data) { toast(error?.message || 'This report has already changed.',true); return; }
  $('#reject-dialog').close(); pendingRejectId = null; toast('Report rejected. The reporter can update and resubmit it.'); renderView(currentView);
});
$('#cancel-reject').addEventListener('click',() => $('#reject-dialog').close());

function renderUsers(profiles) {
  const content = $('#admin-content');
  content.innerHTML = `<div class="admin-page-heading"><div><h1>Manage users</h1><p>Approve or deny accounts. Changes apply to both the web and Flutter app.</p></div><input class="user-search" id="user-search" type="search" placeholder="Search name or email" /></div><div id="admin-user-list" class="admin-user-list"></div>`;
  $('#user-search').addEventListener('input',() => filterUsers(profiles));
  filterUsers(profiles);
}

function filterUsers(profiles) {
  const list = $('#admin-user-list'); if (!list) return;
  const term = ($('#user-search').value || '').trim().toLowerCase();
  const visible = profiles.filter(user => `${user.full_name || ''} ${user.email || ''}`.toLowerCase().includes(term));
  list.innerHTML = visible.length ? visible.map(user => `<article class="surface-card admin-user-card"><div><h3>${esc(user.full_name || 'NEU user')}</h3><p>${esc(user.email || '')}</p></div><span class="admin-user-role">${esc(user.role || 'user').toUpperCase()}</span><select aria-label="Account status for ${esc(user.email)}" data-status="${esc(user.id)}"${user.role === 'admin' ? ' disabled' : ''}><option value="pending"${user.account_status === 'pending'?' selected':''}>Pending</option><option value="approved"${user.account_status === 'approved'?' selected':''}>Approved</option><option value="denied"${user.account_status === 'denied'?' selected':''}>Denied</option></select><button class="save-user" data-save-user="${esc(user.id)}"${user.role === 'admin'?' disabled':''}>Save status</button></article>`).join('') : '<div class="surface-card admin-empty">No users match that search.</div>';
  $$('[data-save-user]',list).forEach(button => button.addEventListener('click',() => updateUser(button.dataset.saveUser,button)));
}

async function updateUser(id,button) {
  const status = $(`[data-status="${CSS.escape(id)}"]`).value;
  button.disabled = true; button.textContent = 'Saving…';
  const {data,error} = await supabase.from('profiles').update({account_status:status}).eq('id',id).select('id').maybeSingle();
  button.disabled = false; button.textContent = 'Save status';
  if (error || !data) { toast(error?.message || 'Could not update this account.',true); return; }
  toast('User access updated.'); renderView('users');
}

$$('[data-view]').forEach(button => button.addEventListener('click',() => renderView(button.dataset.view)));
$('#admin-refresh').addEventListener('click',() => renderView(currentView));
$('#admin-logout').addEventListener('click',() => supabase.auth.signOut());
$('#forgot-password').addEventListener('click',async event => {
  event.preventDefault();
  const email = String($('[name="email"]','#admin-login-form').value || '').trim();
  const message = $('#admin-login-message');
  if (!email) { message.textContent = 'Enter your admin email first.'; return; }
  message.textContent = '';
  const {error} = await supabase.auth.resetPasswordForEmail(email,{redirectTo:`${window.location.origin}/admin/`});
  message.textContent = error ? error.message : 'If this account exists, a password reset link has been sent.';
});
$('#password-reset-form').addEventListener('submit',async event => {
  event.preventDefault();
  const password = String(new FormData(event.currentTarget).get('password') || '');
  const message = $('#password-reset-message');
  const button = $('button[type="submit"]',event.currentTarget);
  message.textContent = ''; button.disabled = true;
  const {error} = await supabase.auth.updateUser({password});
  button.disabled = false;
  if (error) { message.textContent = error.message; return; }
  $('#password-reset-dialog').close();
  toast('Password updated. Signing you in…');
  const {data:{session}} = await supabase.auth.getSession();
  await verifyAndEnter(session);
});
$('#admin-login-form').addEventListener('submit',async event => {
  event.preventDefault();
  const form = new FormData(event.currentTarget); const message = $('#admin-login-message'); const button = $('button[type="submit"]',event.currentTarget);
  message.textContent = ''; button.disabled = true; button.textContent = 'Signing in…';
  const {data,error} = await supabase.auth.signInWithPassword({email:String(form.get('email')).trim(),password:String(form.get('password'))});
  button.disabled = false; button.textContent = 'Sign in to Admin';
  if (error) { message.textContent = error.message; return; }
  await verifyAndEnter(data.session);
});
supabase.auth.onAuthStateChange((event,nextSession) => {
  if (event === 'PASSWORD_RECOVERY') $('#password-reset-dialog').showModal();
  if (!nextSession) { adminUser = null; showPortal(false); }
});
const {data:{session}} = await supabase.auth.getSession();
await verifyAndEnter(session);
