class Auth:
	CLIENT_ID = "815886444860-da8she5k79pp3gi8gitb5evp0k2kggrs.apps.googleusercontent.com"
	CLIENT_SECRET = "9_Z_5dKU-n8flrPDgs6ZBYRv"
	REDIRECT_URI = 'https://localhost:5000/gCallback'
	AUTH_URI = 'https://accounts.google.com/o/oauth2/auth'
	TOKEN_URI = 'https://accounts.google.com/o/oauth2/token'
	USER_INFO = 'https://www.googleapis.com/userinfo/v2/me'
	SCOPE = ['https://www.googleapis.com/auth/userinfo.profile', 'https://www.googleapis.com/auth/userinfo.email']
