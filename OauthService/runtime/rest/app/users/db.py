from flask_sqlalchemy import SQLAlchemy
from flask_login import UserMixin
from runtime.rest.app import db
import os
import datetime

class User(db.Model, UserMixin):
	__tablename__ = "user"
	id = db.Column(db.Integer, autoincrement=True, primary_key=True)
	name = db.Column(db.String(255),nullable=False)    
	email = db.Column(db.String(255), unique=True, nullable=False)

	def __repr__(self):
		return 'User\'s Id is: %d, User\'s Name is: %r & User\'s Email is: %r>' %(self.id, self.name, self.email)

	def to_dict(self):
		return {
			'id' : self.id,
			'name': self.name,
			'email': self.email,
			'role': self.role
		}

class Client(db.Model):
	__tablename__="client"

	name = db.Column(db.String(255),nullable=False)
	client_id = db.Column(db.String(40), primary_key=True,unique=True)
	client_secret = db.Column(db.String(55), nullable=False,unique=True)
	user_id = db.Column(db.ForeignKey('user.id'),nullable=False)

	_redirect_uris = db.Column(db.Text)
	_default_scopes = db.Column(db.Text)

	@property
	def client_type(self):
		return 'public'

	@property
	def redirect_uris(self):
		if self._redirect_uris:
			return self._redirect_uris.split()
		return []

	@property
	def default_redirect_uri(self):
		return self.redirect_uris[0]

	@property
	def default_scopes(self):
		if self._default_scopes:
			return self._default_scopes.split()
		return []		

class Grant(db.Model):
	id = db.Column(db.Integer, primary_key=True)

	user_id = db.Column(
		db.Integer, db.ForeignKey('user.id', ondelete='CASCADE')
	)

	client_id = db.Column(
		db.String(40), db.ForeignKey('client.client_id'),
		nullable=False,
	)

	code = db.Column(db.String(255), index=True, nullable=False)

	redirect_uri = db.Column(db.String(255))
	expires = db.Column(db.DateTime)

	_scopes = db.Column(db.Text)

	def delete(self):
		db.session.delete(self)
		db.session.commit()
		return self

	@property
	def scopes(self):
		if self._scopes:
			return self._scopes.split()
		return []


class Token(db.Model):
	id = db.Column(db.Integer, primary_key=True)

	client_id = db.Column(
		db.String(40), db.ForeignKey('client.client_id'),
		nullable=False,
	)

	user_id = db.Column(
		db.Integer, db.ForeignKey('user.id')
	)
	# currently only bearer is supported
	token_type = db.Column(db.String(40))

	access_token = db.Column(db.String(255), unique=True)
	refresh_token = db.Column(db.String(255), unique=True)
	expires = db.Column(db.DateTime)
	_scopes = db.Column(db.Text)

	@property
	def scopes(self):
		if self._scopes:
			return self._scopes.split()
		return []
