import sys, os

BASE_DIR = BASE_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)))

#sys.path.insert(0, BASE_DIR)
sys.path.insert(0, "/var/www")

from runtime.rest.run import application
