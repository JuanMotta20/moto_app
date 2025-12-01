bool isValidEmail(String email) {
	final emailRegex = RegExp(r"^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}");
	return emailRegex.hasMatch(email);
}

bool isValidPhone(String phone) {
	final phoneDigits = phone.replaceAll(RegExp(r'[^0-9]'), '');
	return phoneDigits.length >= 7; // simple check
}

bool isValidPassword(String password) {
	return password.length >= 6;
}
