# Import flask modules and template operators
from flask import Flask, render_template, request, session, jsonify,redirect,url_for
from flask_oauth import OAuth
from flask_login import LoginManager, login_required, login_user, \
	logout_user, current_user, UserMixin
from flask_sqlalchemy import SQLAlchemy
import os
import time
from functools import wraps
from flask_oauthlib.provider import OAuth2Provider

from flask_cors import CORS,cross_origin

# Initialize your application using flask, it will be referred to as app.
# Import the configuration from the config file.
app = Flask(__name__,static_url_path = '/static')
app.config.from_object("runtime.config.flask_app_config")
app.config['TRAP_HTTP_EXCEPTIONS']=True

# Build the database:

db = SQLAlchemy(app)
oauth = OAuth2Provider(app)
CORS(app)

# Our authentication provider
# Initialize a Login Manager for our app.
# Initialize a OAuth for our app that can be used for Google OAuth login.
login_manager = LoginManager(app)
login_manager.login_view = "users.login"
login_manager.session_protection = "strong"
oauth = OAuth()

def require_login(f):
	@wraps(f)
	def decorated(*args, **kwargs):	
		if current_user.is_authenticated == False:
			return redirect(url_for('users.login', next=request.url))
		return f(*args,**kwargs)

	return decorated

#App 404 error handler, redirects to 404.html whenever non exitent/registered
#route is tried to be accessed.
# @app.errorhandler(404)
# def handle_404(e):
# 	print(e)
# 	return jsonify(sucess=False,message="404 Not found") , 404

#LoginManager decorated user_loader function to intialise current_user If your
#models are declared in a separate module, import them before calling
#create_all()
from runtime.rest.app.users.db import User
db.create_all()

@login_manager.user_loader
def load_user(user_id):
	return User.query.get(int(user_id))

# Register blueprint(s) which is generally a template for generating main
# section of our web application.  In order to visit the routes in our api we
# need to register our blueprint (like in unittesting)
from runtime.rest.app.users.api import api
app.register_blueprint(api)

#Workaround for socket file pipes not getting enough time to restart while changes are made in debugger mode.
# time.sleep(1)
