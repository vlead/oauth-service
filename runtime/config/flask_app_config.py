import os

# Defining Base Dir
BASE_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__),'..'))  
UPLOAD_BASE = os.path.abspath(os.path.join(BASE_DIR, 'uploads'))

# Our Database
# SQLALCHEMY_DATABASE_URI = 'sqlite:///' + os.path.join(BASE_DIR, 'safe.db')
# On production <text> needs to be changed like this example
SQLALCHEMY_DATABASE_URI = 'mysql+mysqldb://root:iiit123@localhost:3306/IDP'

# Debug from SQLAlchemy
# Turn TRACK_MODIFICATIONS and ECHO to 'False' on production
SQLALCHEMY_ECHO = False
DATABASE_CONNECT_OPTIONS = {}
SQLALCHEMY_TRACK_MODIFICATIONS = True

# Cross-origin resource sharing (CORS) is a mechanism that allows restricted resources on a web page  to be requested from another domain.
# Which is outside the domain from which the first resource was served.
# List of allowed origins for CORS for this app
ALLOWED_ORIGINS = "['*']"

# List of allowed IPs
WHITELIST_IPS = ["127.0.0.1"]

# Configure your log paths
LOG_FILE_DIRECTORY = 'logs'
LOG_FILE = 'ldsdashboard.log'

# Log level for the application
# 10=DEBUG, 20=INFO, 30=WARNING, 40=ERROR, 50=CRITICAL",
LOG_LEVEL = 10

# Application threads. A common general assumption is
# using 2 per available processor cores - to handle
# incoming requests using one and performing background
# operations using the other.
THREADS_PER_PAGE = 2


# In order to use sessions you have to set a secret key. 
# Prevents users to modify your cookie without this secret key.
SECRET_KEY = os.urandom(13)
SESSION_COOKIE_NAME="Oauth"

# These are meant to be initialized inorder to be used for bypassing login_required decorator and custom decorators during build.
LOGIN_REQUIRED = True
TESTING = True
