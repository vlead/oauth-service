from flask import Flask
from runtime.rest.app import db
from runtime.rest.app.users.db import *

def populate():
    role1 = Roles(role_name="admin")
    role1.save()
    user = User(name="admin_user",
                email="admin@email.com",
                role="admin")
    user.save()

if __name__ == "__main__":
    app = Flask(__name__)
    app.config.from_object("runtime.config.flask_app_config")
    db.create_all()
    populate()
