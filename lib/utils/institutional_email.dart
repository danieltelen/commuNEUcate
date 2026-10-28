const institutionalEmailDomain = 'neu.edu.ph';

bool isInstitutionalEmail(String email) {
  final normalizedEmail = email.trim().toLowerCase();
  final atIndex = normalizedEmail.lastIndexOf('@');
  if (atIndex <= 0 || atIndex == normalizedEmail.length - 1) return false;
  return normalizedEmail.substring(atIndex + 1) == institutionalEmailDomain;
}
