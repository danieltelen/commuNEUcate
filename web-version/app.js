import { supabase } from './backend.js';

const $ = (selector, root = document) => root.querySelector(selector);
const $$ = (selector, root = document) => [...root.querySelectorAll(selector)];
const esc = (value = '') => String(value).replace(/[&<>"']/g, char => ({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[char]));
const categories = ['All Items','Electronics','Accessories','Documents','Clothing','Others'];
const glyph = {Electronics:'▣',Accessories:'◈',Documents:'▤',Clothing:'◇',Others:'▧'};
let session = null;
let page = 'browse';
let allItems = [];
let activeCategory = 'All Items';
let authMode = 'login';
let toastTimer;

function toast(message, error = false) {
  const node = $('#toast'); node.textContent = message;
  node.classList.toggle('error', error); node.classList.add('show');
  clearTimeout(toastTimer); toastTimer = setTimeout(() => node.classList.remove('show'), 3400);
}

function currentProfile() {
  return session?.user?.user_metadata || {};
}

function renderAccount() {
  const signIn = $('#auth-open');
  const account = $('#public-account');
  if (session?.user) {
    signIn.classList.add('hidden'); account.classList.remove('hidden');
    account.innerHTML = `<span>${esc(session.user.email || 'NEU user')}</span><button id="sign-out" class="signout-link">Sign out</button>`;
    $('#sign-out').addEventListener('click', () => supabase.auth.signOut());
  } else {
    signIn.classList.remove('hidden'); account.classList.add('hidden'); account.textContent = '';
  }
  $$('.auth-required').forEach(element => element.classList.toggle('hidden', !session?.user));
}

function setPage(nextPage) {
  page = nextPage;
  $$('.public-nav-link').forEach(link => link.classList.toggle('active', link.dataset.page === page));
  if (page === 'browse') renderBrowse();
  else if (!session?.user) openAuth('login', `Sign in to ${page === 'report' ? 'report an item' : 'see your reports'}.`);
  else if (page === 'report') checkAccessAndRenderReport();
  else if (page === 'my-reports') checkAccessAndRenderReports();
}

async function renderBrowse() {
  const root = $('#page-root');
  root.innerHTML = `<section class="public-hero"><div class="hero-copy"><span class="hero-kicker"><i></i> NEW ERA UNIVERSITY <span aria-hidden="true">&middot;</span> LOST &amp; FOUND</span><h1>Find what matters.<br /><span>Help it find its way<br class="hero-mobile-break" /> home.</span></h1><p>A shared campus board for found items. Search freely, then follow the secure steps to report or claim an item.</p><button class="primary-button hero-report" data-page="report">Report a found item <span aria-hidden="true">&rarr;</span></button><div class="hero-proof"><span><b></b> Community powered</span><span><b></b> Reviewed by NEU admins</span></div></div><div class="hero-art" aria-hidden="true"><div class="hero-orb"></div><div class="hero-ring ring-one"></div><div class="hero-ring ring-two"></div><span class="hero-float float-one"><i>▣</i> Keys</span><span class="hero-float float-two"><i>▤</i> ID card</span><span class="hero-float float-three"><i>◈</i> Earbuds</span><span class="hero-art-label">FOUND ON CAMPUS <b>01 / COMMUNITY BOARD</b></span></div></section>
    <section class="board-section" aria-labelledby="board-title"><div class="board-heading"><div><span class="section-kicker">CAMPUS COMMUNITY</span><h2 id="board-title">Recently found</h2><p>Find a match by item, category, or where it was found.</p></div><button id="refresh-board" class="refresh-button" type="button"><span aria-hidden="true">&#8635;</span> Refresh</button></div>
      <div class="board-controls"><div class="board-tools"><label class="search-box"><svg aria-hidden="true" viewBox="0 0 24 24"><circle cx="10.8" cy="10.8" r="6.8"></circle><path d="m16 16 4.4 4.4"></path></svg><input id="item-search" type="search" placeholder="Search items, tags, locations..." autocomplete="off" /><button id="clear-search" class="clear-search" type="button" aria-label="Clear search" hidden>&times;</button></label><label class="sort-control"><span>Sort</span><select id="item-sort" aria-label="Sort found items"><option value="newest">Newest first</option><option value="oldest">Oldest first</option><option value="name">Name A to Z</option></select></label></div><div id="category-filters" class="filter-row" aria-label="Filter items by category">${categories.map(category => `<button class="filter-chip${category === activeCategory ? ' active' : ''}" data-category="${esc(category)}" type="button" aria-pressed="${category === activeCategory}">${esc(category)}</button>`).join('')}</div></div>
      <div class="board-result-row"><span id="item-count" role="status" aria-live="polite">Loading found items...</span><span>Every claim is reviewed by the NEU admin team.</span></div><div id="item-grid" class="public-item-grid"><div class="empty-state"><span class="spinner"></span> Loading found items...</div></div>
    </section>`;
  $$('[data-page="report"]', root).forEach(button => button.addEventListener('click', () => setPage('report')));
  $('#item-search').addEventListener('input', filterItems);
  $('#clear-search').addEventListener('click', () => { $('#item-search').value = ''; filterItems(); $('#item-search').focus(); });
  $('#item-sort').addEventListener('change', filterItems);
  $('#refresh-board').addEventListener('click', loadItems);
  $$('.filter-chip', root).forEach(chip => chip.addEventListener('click', () => {
    activeCategory = chip.dataset.category;
    $$('.filter-chip', root).forEach(item => {
      const selected = item === chip;
      item.classList.toggle('active', selected);
      item.setAttribute('aria-pressed', String(selected));
    });
    filterItems();
  }));
  $('#item-grid').addEventListener('click', event => {
    const button = event.target.closest('[data-item-details]');
    if (!button) return;
    const item = allItems.find(entry => String(entry.id) === button.dataset.itemDetails);
    if (item) renderItemDetails(item);
  });
  await loadItems();
}

async function loadItems() {
  const grid = $('#item-grid');
  if (!grid) return;
  const refresh = $('#refresh-board');
  if (refresh) { refresh.disabled = true; refresh.classList.add('is-loading'); }
  grid.innerHTML = '<div class="empty-state"><span class="spinner"></span> Loading found items...</div>';
  try {
    const { data, error } = await supabase.from('public_reports').select('*').order('created_at',{ascending:false}).limit(100);
    if (error) throw error;
    allItems = data || [];
    filterItems();
  } catch (error) {
    console.error('Public report list failed:', error);
    grid.innerHTML = '<div class="empty-state">The item board is temporarily unavailable. Please refresh in a moment.</div>';
    const count = $('#item-count');
    if (count) count.textContent = 'Items could not be loaded';
  } finally {
    if (refresh) { refresh.disabled = false; refresh.classList.remove('is-loading'); }
  }
}

function filterItems() {
  const grid = $('#item-grid');
  if (!grid) return;
  const term = ($('#item-search')?.value || '').trim().toLowerCase();
  const items = allItems.filter(item => {
    const text = [item.item_name,item.location_found,item.tags,item.description].join(' ').toLowerCase();
    return (activeCategory === 'All Items' || item.category === activeCategory) && (!term || term.split(/\s+/).some(word => text.includes(word)));
  });
  const sort = $('#item-sort')?.value || 'newest';
  items.sort((a, b) => {
    if (sort === 'name') return String(a.item_name || '').localeCompare(String(b.item_name || ''));
    const dateA = Date.parse(a.created_at || a.date_found || 0) || 0;
    const dateB = Date.parse(b.created_at || b.date_found || 0) || 0;
    return sort === 'oldest' ? dateA - dateB : dateB - dateA;
  });
  const count = $('#item-count');
  if (count) count.textContent = `${items.length} ${items.length === 1 ? 'item' : 'items'}${activeCategory !== 'All Items' ? ` in ${activeCategory}` : ''}${term ? ` matching “${term}”` : ''}`;
  const clear = $('#clear-search');
  if (clear) clear.hidden = !term;
  grid.innerHTML = items.length ? items.map(item => `<article class="public-item surface-card"><div class="public-item-visual">${item.image_url ? `<img class="public-item-image" src="${esc(item.image_url)}" alt="${esc(item.item_name || 'Found item')}" loading="lazy" />` : `<div class="public-item-placeholder" aria-hidden="true">${glyph[item.category] || glyph.Others}</div>`}<span class="item-status-badge${item.status === 'claimed' ? ' claimed' : ''}"><i></i>${item.status === 'claimed' ? 'Claimed' : 'Available'}</span></div><div class="public-item-body"><div class="item-category">${esc(item.category || 'Other')}</div><h3>${esc(item.item_name || 'Found item')}</h3><p>${esc(item.description || 'A community member found this item.')}</p><div class="public-item-meta"><span><svg aria-hidden="true" viewBox="0 0 24 24"><path d="M20 10c0 5-8 12-8 12S4 15 4 10a8 8 0 1 1 16 0Z"></path><circle cx="12" cy="10" r="2.5"></circle></svg>${esc(item.location_found || 'NEU campus')}</span><span>${formatDate(item.date_found)}</span></div><button class="item-details-button" type="button" data-item-details="${esc(item.id)}" aria-label="View details for ${esc(item.item_name || 'found item')}">View details <span aria-hidden="true">&rarr;</span></button></div></article>`).join('') : `<div class="empty-state board-empty"><span class="empty-icon">⌕</span><strong>No matching items</strong><p>Try a different search or clear the filters.</p><button type="button" class="secondary-button" id="reset-board">Clear search and filters</button></div>`;
  $('#reset-board')?.addEventListener('click', () => {
    $('#item-search').value = '';
    activeCategory = 'All Items';
    $$('.filter-chip').forEach(chip => {
      const selected = chip.dataset.category === activeCategory;
      chip.classList.toggle('active', selected);
      chip.setAttribute('aria-pressed', String(selected));
    });
    filterItems();
  });
}

function formatDate(value) {
  if (!value) return 'Date not provided';
  const parsed = new Date(`${String(value).slice(0, 10)}T00:00:00`);
  if (Number.isNaN(parsed.getTime())) return 'Date not provided';
  return new Intl.DateTimeFormat(undefined, { dateStyle: 'medium' }).format(parsed);
}

function renderItemDetails(item) {
  const claimed = item.status === 'claimed';
  const tags = String(item.tags || '').split(/[,|]/).map(tag => tag.trim()).filter(Boolean);
  const root = $('#item-dialog-content');
  root.innerHTML = `<div class="item-detail-layout"><div class="item-detail-visual">${item.image_url ? `<img src="${esc(item.image_url)}" alt="${esc(item.item_name || 'Found item')}" />` : `<div class="item-detail-placeholder" aria-hidden="true">${glyph[item.category] || glyph.Others}</div>`}<span class="item-status-badge${claimed ? ' claimed' : ''}"><i></i>${claimed ? 'Claimed' : 'Available'}</span></div><div class="item-detail-content"><span class="item-category">${esc(item.category || 'Other')}</span><h2 id="item-dialog-title">${esc(item.item_name || 'Found item')}</h2><p class="item-detail-description">${esc(item.description || 'No additional description was provided.')}</p><div class="item-facts"><div><span>LOCATION FOUND</span><strong>${esc(item.location_found || 'NEU campus')}</strong></div><div><span>DATE FOUND</span><strong>${esc(formatDate(item.date_found))}</strong></div></div>${tags.length ? `<div class="detail-tags"><span>ITEM TAGS</span><div>${tags.map(tag => `<span class="detail-tag">${esc(tag)}</span>`).join('')}</div></div>` : ''}${item.security_question ? `<div class="security-question"><span>OWNER CHECK</span><strong>${esc(item.security_question)}</strong><small>Only the owner should know this answer. Your answer is shared with administrators for review.</small></div>` : ''}<div class="detail-actions">${claimed ? '<span class="claimed-message">This item has been marked as claimed.</span>' : `<button class="primary-button detail-claim-button" type="button" data-claim-item="${esc(item.id)}">This is mine <span aria-hidden="true">&rarr;</span></button>`}<span class="detail-help">Claims are reviewed by the NEU admin team.</span></div></div></div>`;
  $('[data-claim-item]', root)?.addEventListener('click', () => startClaim(item));
  $('#item-dialog').showModal();
}

async function startClaim(item) {
  if (!session?.user) {
    openAuth('login', 'Sign in with your approved NEU account to submit a claim.');
    return;
  }
  if (!(await requireApprovedAccess())) return;
  const { data: report, error: reportError } = await supabase.from('reports').select('reporter_id,status').eq('id', item.id).maybeSingle();
  if (reportError || !report) { toast('This item is no longer available to claim.', true); return; }
  if (report.reporter_id === session.user.id) { toast('You cannot claim an item from your own report.'); return; }
  if (report.status !== 'unclaimed') { toast('This item is no longer available to claim.'); return; }
  const { data: priorClaims, error } = await supabase.from('claims').select('id,status')
    .eq('report_id', item.id).eq('claimer_id', session.user.id);
  if (error) { toast('Could not check your claim history. Please try again.', true); return; }
  if ((priorClaims || []).some(claim => ['pending', 'approved'].includes(claim.status))) {
    toast('You already have an active claim for this item.');
    return;
  }
  $('#claim-form').reset();
  $('[name="report_id"]', $('#claim-form')).value = item.id;
  $('#claim-dialog-title').textContent = `Claim ${item.item_name || 'this item'}`;
  $('#claim-message').textContent = '';
  $('#claim-message').classList.remove('error');
  $('#claim-submit').disabled = false;
  $('#claim-submit').textContent = 'Submit claim';
  if ($('#item-dialog').open) $('#item-dialog').close();
  $('#claim-dialog').showModal();
}

async function submitClaim(event) {
  event.preventDefault();
  const form = event.currentTarget;
  const values = new FormData(form);
  const button = $('#claim-submit');
  const message = $('#claim-message');
  const proof = form.elements.proof.files[0];
  const reportId = values.get('report_id');
  if (!session?.user) { openAuth('login', 'Sign in to submit this claim.'); return; }
  if (!proof || !proof.type.startsWith('image/')) {
    message.textContent = 'Choose an image file as proof of ownership.';
    message.classList.add('error');
    return;
  }
  if (proof.size > 10 * 1024 * 1024) {
    message.textContent = 'Choose an image smaller than 10 MB.';
    message.classList.add('error');
    return;
  }
  button.disabled = true;
  button.textContent = 'Submitting claim...';
  message.textContent = '';
  message.classList.remove('error');
  let proofPath = '';
  let claimCreated = false;
  try {
    const extension = (proof.name.split('.').pop() || 'jpg').replace(/[^a-zA-Z0-9]/g, '').toLowerCase() || 'jpg';
    proofPath = `${session.user.id}/proof_${Date.now()}.${extension}`;
    const upload = await supabase.storage.from('claim_proofs').upload(proofPath, proof, { upsert: false });
    if (upload.error) throw upload.error;
    const claim = await supabase.from('claims').insert({
      report_id: reportId,
      claimer_id: session.user.id,
      security_answer: String(values.get('security_answer') || '').trim(),
      proof_image_url: proofPath,
      status: 'pending',
    }).select('id').single();
    if (claim.error) throw claim.error;
    claimCreated = true;
    const updated = await supabase.from('reports').update({ status: 'pending_review' })
      .eq('id', reportId).eq('status', 'unclaimed').select('id').maybeSingle();
    if (updated.error || !updated.data) {
      console.error('Claim saved but item status update failed:', updated.error);
      message.textContent = 'Your claim was saved, but the item could not be moved into review. Contact an administrator; your submission is on file.';
      button.textContent = 'Claim submitted';
      return;
    }
    $('#claim-dialog').close();
    form.reset();
    toast('Claim submitted for administrator review.');
    await loadItems();
  } catch (error) {
    console.error('Claim submission failed:', error);
    if (proofPath && !claimCreated) {
      const cleanup = await supabase.storage.from('claim_proofs').remove([proofPath]);
      if (cleanup.error) console.warn('Could not remove unreferenced claim proof:', cleanup.error);
    }
    message.textContent = error.message || 'Could not submit your claim. Please try again.';
    message.classList.add('error');
    button.disabled = false;
    button.textContent = 'Submit claim';
  }
}

async function requireApprovedAccess() {
  if (!session?.user) { openAuth('login', 'Sign in with your NEU account to continue.'); return false; }
  const { data, error } = await supabase.from('profiles').select('role,account_status').eq('id',session.user.id).maybeSingle();
  if (error || !data) { toast('Your account profile is not ready. Try again later.',true); return false; }
  if (data.role !== 'admin' && data.account_status !== 'approved') {
    toast(data.account_status === 'denied' ? 'Your account was not approved. Contact an administrator.' : 'Your account is waiting for administrator approval.');
    return false;
  }
  return true;
}

async function checkAccessAndRenderReport() {
  if (await requireApprovedAccess()) renderReportForm();
  else setPage('browse');
}

async function checkAccessAndRenderReports() {
  if (await requireApprovedAccess()) renderMyReports();
  else setPage('browse');
}

function renderReportForm(report = null) {
  page = 'report';
  $$('.public-nav-link').forEach(link => link.classList.toggle('active', link.dataset.page === page));
  const root = $('#page-root');
  root.innerHTML = `<section class="form-page"><button class="back-link" data-page="browse">← Back to found items</button><div class="form-page-heading"><span class="section-kicker">${report ? 'UPDATE YOUR SUBMISSION' : 'HELP RETURN AN ITEM'}</span><h1>${report ? 'Update & resubmit' : 'Report a found item'}</h1><p>${report ? 'Make the requested changes and send your item back for review.' : 'Share a few details so its owner can find it.'}</p></div>${report?.review_note ? `<div class="review-note"><strong>Admin feedback</strong><p>${esc(report.review_note)}</p></div>` : ''}
      <form id="user-report-form" class="report-form"><input type="hidden" name="report_id" value="${report ? esc(report.id) : ''}" />
        <section class="surface-card form-card"><h2>Item photo</h2><label class="upload-box" for="item-photo"><span id="photo-name">${report?.image_url ? 'Photo uploaded — choose a replacement' : '＋ &nbsp; Add a photo (optional)'}</span><input id="item-photo" name="image" type="file" accept="image/*" /></label></section>
        <section class="surface-card form-card"><h2>Item details</h2><div class="field-grid"><label class="field">ITEM NAME<input name="item_name" required maxlength="120" value="${esc(report?.item_name || '')}" placeholder="What did you find?" /></label><label class="field">CATEGORY<select name="category" required><option value="">Select a category</option>${categories.slice(1).map(category => `<option${report?.category === category ? ' selected' : ''}>${category}</option>`).join('')}</select></label><label class="field">LOCATION FOUND<input name="location_found" required maxlength="160" value="${esc(report?.location_found || '')}" placeholder="Where did you find it?" /></label><label class="field">DATE FOUND<input name="date_found" type="date" required value="${esc(report?.date_found || new Date().toISOString().slice(0,10))}" /></label><label class="field full">DESCRIPTION<textarea name="description" maxlength="1000" placeholder="Add details that will help identify the item">${esc(report?.description || '')}</textarea></label><label class="field full">TAGS<input name="tags" maxlength="200" value="${esc(report?.tags || '')}" placeholder="e.g. blue, wireless, case" /></label></div></section>
        <section class="surface-card form-card"><h2>Claim verification</h2><div class="field-grid"><label class="field">SECURITY QUESTION<input name="security_question" required value="${esc(report?.security_question || '')}" placeholder="A detail only the owner would know" /></label><label class="field">EXPECTED ANSWER<input name="expected_answer" required placeholder="Private — only shown to admins" /></label></div></section>
        <p id="report-message" class="message" role="status"></p><button id="report-submit" class="primary-button submit-report" type="submit">${report ? 'Resubmit for review' : 'Submit report'}</button>
      </form></section>`;
  $('[data-page="browse"]', root).addEventListener('click', () => setPage('browse'));
  $('#item-photo').addEventListener('change', event => { $('#photo-name').textContent = event.target.files[0]?.name || '＋  Add a photo (optional)'; });
  $('#user-report-form').addEventListener('submit', submitUserReport);
  if (report) loadReportSecret(report.id);
}

async function loadReportSecret(reportId) {
  const { data, error } = await supabase.from('report_secrets').select('expected_answer').eq('report_id',reportId).maybeSingle();
  if (error) { toast('Could not load your private verification answer.',true); return; }
  const field = $('[name="expected_answer"]');
  if (field && data) field.value = data.expected_answer || '';
}

async function submitUserReport(event) {
  event.preventDefault();
  const form = event.currentTarget;
  const button = $('#report-submit');
  const message = $('#report-message');
  const values = new FormData(form);
  const reportId = values.get('report_id');
  button.disabled = true; button.textContent = 'Submitting…'; message.textContent = ''; message.classList.remove('error');
  let imageUrl = null;
  try {
    const selectedImage = $('#item-photo').files[0];
    if (selectedImage) {
      const extension = (selectedImage.name.split('.').pop() || 'jpg').replace(/[^a-zA-Z0-9]/g,'');
      const path = `${session.user.id}/${Date.now()}.${extension}`;
      const upload = await supabase.storage.from('item_images').upload(path,selectedImage,{upsert:false});
      if (upload.error) throw upload.error;
      imageUrl = supabase.storage.from('item_images').getPublicUrl(path).data.publicUrl;
    }
    const row = {
      item_name: String(values.get('item_name')).trim(), category: String(values.get('category')),
      location_found: String(values.get('location_found')).trim(), date_found: String(values.get('date_found')),
      description: String(values.get('description') || '').trim(), tags: String(values.get('tags') || '').trim(),
      security_question: String(values.get('security_question')).trim(),
    };
    if (imageUrl) row.image_url = imageUrl;
    if (reportId) {
      const existing = allItems.find(item => String(item.id) === String(reportId));
      const { data: prior } = await supabase.from('reports').select('revalidation_count').eq('id',reportId).eq('reporter_id',session.user.id).eq('status','rejected').maybeSingle();
      if (!prior) throw new Error('This report is no longer available for resubmission. Refresh My Reports.');
      const secret = await supabase.from('report_secrets').upsert({report_id:reportId,expected_answer:String(values.get('expected_answer')).trim()});
      if (secret.error) throw secret.error;
      const update = await supabase.from('reports').update({...row,status:'pending_review',review_note:null,reviewed_at:null,reviewed_by:null,revalidation_count:(prior.revalidation_count || 0)+1})
        .eq('id',reportId).eq('reporter_id',session.user.id).eq('status','rejected').select('id').maybeSingle();
      if (update.error) throw update.error;
      if (!update.data) throw new Error('This report changed while you were editing it. Refresh My Reports.');
      void existing;
      toast('Report resubmitted for review.');
    } else {
      row.reporter_id = session.user.id;
      row.status = 'pending_review';
      if (imageUrl) row.image_url = imageUrl;
      const inserted = await supabase.from('reports').insert(row).select('id').single();
      if (inserted.error) throw inserted.error;
      const secret = await supabase.from('report_secrets').insert({report_id:inserted.data.id,expected_answer:String(values.get('expected_answer')).trim()});
      if (secret.error) {
        await supabase.from('reports').delete().eq('id',inserted.data.id).eq('reporter_id',session.user.id);
        throw secret.error;
      }
      toast('Report submitted for review.');
    }
    await renderMyReports();
  } catch (error) {
    console.error('Report submission failed:', error);
    message.textContent = error.message || 'Could not submit this report. Please try again.';
    message.classList.add('error'); button.disabled = false; button.textContent = reportId ? 'Resubmit for review' : 'Submit report';
  }
}

async function renderMyReports() {
  page = 'my-reports';
  $$('.public-nav-link').forEach(link => link.classList.toggle('active', link.dataset.page === page));
  const root = $('#page-root');
  root.innerHTML = '<section class="form-page"><div class="spinner"></div></section>';
  const { data, error } = await supabase.from('reports').select('*').eq('reporter_id',session.user.id).order('created_at',{ascending:false});
  if (error) {
    root.innerHTML = '<section class="form-page"><h1>My Reports</h1><div class="empty-state">Your reports are unavailable. Check your account approval and try again.</div></section>';
    return;
  }
  const reports = data || [];
  root.innerHTML = `<section class="form-page"><div class="board-heading"><div><span class="section-kicker">YOUR SUBMISSIONS</span><h1>My Reports</h1><p>Track review status and resubmit rejected reports.</p></div><button class="primary-button compact-button" id="new-report">＋ New report</button></div><div class="my-report-list">${reports.length ? reports.map(report => {
    const status = String(report.status || 'pending_review').replaceAll('_',' ');
    const rejected = report.status === 'rejected';
    return `<article class="my-report-card surface-card">${report.image_url ? `<img src="${esc(report.image_url)}" alt="${esc(report.item_name)}" />` : `<div class="my-report-placeholder">${glyph[report.category] || '▧'}</div>`}<div class="my-report-info"><div class="report-status ${rejected?'rejected':''}">${esc(status)}</div><h3>${esc(report.item_name)}</h3><p>${esc(report.location_found || '')}</p>${rejected && report.review_note ? `<div class="review-note compact"><strong>Admin feedback</strong><p>${esc(report.review_note)}</p></div>` : ''}</div>${rejected ? `<button class="secondary-button resubmit-button" data-resubmit="${esc(report.id)}">Update &amp; resubmit</button>` : ''}</article>`;
  }).join('') : '<div class="empty-state">You have not submitted any reports yet.</div>'}</div></section>`;
  $('#new-report').addEventListener('click', () => setPage('report'));
  $$('[data-resubmit]', root).forEach(button => button.addEventListener('click', () => {
    const report = reports.find(item => String(item.id) === button.dataset.resubmit);
    if (report) renderReportForm(report);
  }));
}

function openAuth(mode = 'login', description = '') {
  authMode = mode; updateAuthMode(description); $('#auth-dialog').showModal();
}

function updateAuthMode(description = '') {
  const signup = authMode === 'signup';
  $('#auth-title').textContent = signup ? 'Create your account' : 'Welcome back';
  $('#auth-description').textContent = description || (signup ? 'Create an account with your email address.' : 'Sign in to report items and follow your submissions.');
  $('.auth-name').classList.toggle('hidden',!signup);
  $('.auth-name input').required = signup;
  $('#auth-submit').textContent = signup ? 'Create account' : 'Sign in';
  $('#auth-toggle').textContent = signup ? 'Already have an account? Sign in' : 'Need an account? Create one';
  $('#auth-message').textContent = '';
}

$('#auth-open').addEventListener('click', () => openAuth());
$('#auth-toggle').addEventListener('click', () => { authMode = authMode === 'login' ? 'signup' : 'login'; updateAuthMode(); });
$('#google-login').addEventListener('click', async () => {
  const message = $('#auth-message');
  message.textContent = 'Opening Google sign in…'; message.classList.remove('error');
  const {error} = await supabase.auth.signInWithOAuth({
    provider:'google',
    options:{redirectTo:window.location.origin + window.location.pathname,queryParams:{hd:'neu.edu.ph'}},
  });
  if (error) { message.textContent = error.message; message.classList.add('error'); }
});
$('#auth-form').addEventListener('submit', async event => {
  event.preventDefault();
  const form = new FormData(event.currentTarget);
  const email = String(form.get('email')).trim().toLowerCase();
  const password = String(form.get('password'));
  const message = $('#auth-message');
  const button = $('#auth-submit');
  button.disabled = true; button.textContent = 'Please wait…'; message.textContent = ''; message.classList.remove('error');
  const result = authMode === 'signup'
    ? await supabase.auth.signUp({email,password,options:{data:{full_name:String(form.get('full_name')).trim()}}})
    : await supabase.auth.signInWithPassword({email,password});
  button.disabled = false; updateAuthMode();
  if (result.error) { message.textContent = result.error.message; message.classList.add('error'); return; }
  if (authMode === 'signup') {
    if (result.data.session) await supabase.auth.signOut();
    message.textContent = 'Account created. Verify your email if requested, then wait for administrator approval.';
    return;
  }
  $('#auth-dialog').close(); event.currentTarget.reset();
  toast('Signed in. Browsing is still available without an account.');
});

$$('.public-nav-link').forEach(button => button.addEventListener('click', () => setPage(button.dataset.page)));
$('#auth-dialog').addEventListener('click', event => { if (event.target === $('#auth-dialog')) $('#auth-dialog').close(); });
$('#auth-dialog').addEventListener('close', () => {
  if (!session?.user && page !== 'browse') {
    page = 'browse';
    $$('.public-nav-link').forEach(link => link.classList.toggle('active', link.dataset.page === page));
  }
});
$('#claim-form').addEventListener('submit', submitClaim);
$('#claim-cancel').addEventListener('click', () => $('#claim-dialog').close());
$('#claim-dialog').addEventListener('click', event => { if (event.target === $('#claim-dialog')) $('#claim-dialog').close(); });
supabase.auth.onAuthStateChange((_event,nextSession) => {
  session = nextSession;
  renderAccount();
  if (!session && page !== 'browse') { page = 'browse'; renderBrowse(); }
  else if (session && page === 'report') checkAccessAndRenderReport();
  else if (session && page === 'my-reports') checkAccessAndRenderReports();
});
const { data: { session: restoredSession } } = await supabase.auth.getSession();
session = restoredSession; renderAccount(); renderBrowse();
