# -*- coding: utf-8 -*-
from flask import Blueprint, Flask, url_for, redirect, \
	render_template, session, request, jsonify
from flask_sqlalchemy import SQLAlchemy
from requests.exceptions import HTTPError
from requests_oauthlib import OAuth2Session
from runtime.config.goauth_config import Auth
from runtime.rest.app import app, db,require_login
from runtime.rest.app.users.db import User
import os
import json
import re
import time
from sqlalchemy.exc import IntegrityError
from werkzeug.security import gen_salt

api = Blueprint('users', __name__)
login_session={};

def get_google_auth(state=None, token=None):
	if token:
		return OAuth2Session(Auth.CLIENT_ID, token=token)
	if state:
		return OAuth2Session(
			Auth.CLIENT_ID,
			state=state,
			redirect_uri=Auth.REDIRECT_URI)

	return OAuth2Session(
		Auth.CLIENT_ID,
		redirect_uri=Auth.REDIRECT_URI,
		scope=Auth.SCOPE)
	
@api.route("/", methods=['GET'])
def index():	
	print(login_session)
	return render_template('index.html')

@api.route('/login', methods=["GET","POST"])
def login():
	if 'user' in login_session: 
		return redirect("/")
	google = get_google_auth()
	auth_url, state = google.authorization_url(
		Auth.AUTH_URI, access_type='offline')
	session['oauth_state'] = state
	return redirect(auth_url, code=200)	

@api.route('/gCallback')
def callback():
	if 'error' in request.args:
		if request.args.get('error') == 'access_denied':
			return 'You have been denied access.'
		return 'Error encountered.'
	if 'code' not in request.args and 'state' not in request.args:
		return redirect("/")
	else:
		google = get_google_auth(state=session.get('oauth_state'))
		try:
			token = google.fetch_token(
				Auth.TOKEN_URI,
				client_secret=Auth.CLIENT_SECRET,
				authorization_response=request.url)
		except:
			return jsonify(success=False, message="HTTP connectivity error"), 401

		google = get_google_auth(token=token)
		resp = google.get(Auth.USER_INFO)
		data = resp.json()
		if resp.status_code == 200:
			try:
				next = resp.args.get('next')
			except:
				next='/'

			session['google_token'] = token
			login_session['user'] =data
			return redirect(next) ,200

		return  jsonify(success=False, message="Couldn't fetch information"), 400

@api.route('/logout', methods=["GET"])
def logout():
	if 'user' in login_session :
		try:
			print(login_session)
			login_session.clear()
			session.clear()
		except:
			return jsonify(success=False, message="No session present"), 400

	return redirect("/")

@api.route('/check_login',methods=["GET"])
def check_login():
	if request.method=="GET":
		if 'user' in login_session:		
			return jsonify(loggedIn=True,data=login_session['user'])
		else:	
			return jsonify(loggedIn=False)
	return  jsonify(loggedIn=True)

