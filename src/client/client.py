from flask import Flask, redirect, url_for, session, request, jsonify, abort,render_template
import requests
import requests

from requests.packages.urllib3.exceptions import InsecureRequestWarning
requests.packages.urllib3.disable_warnings(InsecureRequestWarning)

app = Flask(__name__)
app.debug = True    
app.secret_key = 'development'

proxies = {
"http": None,
"https": None,
"all":None
}
# Configure all_proxy correctly 


def check_login():
    r=requests.get('https://0.0.0.0:5000/check_login',verify=False,proxies=proxies)
    print(r)
    data=r.json()
    return data

@app.route('/')
def index():
    return render_template('index.html',data=check_login())

@app.route('/login')
def login():
    return redirect('https://localhost:5000')

@app.route('/logout')
def logout():
    return redirect('https://localhost:5000/logout')

if __name__ == '__main__':
    app.run(host='localhost', port=8000,ssl_context=('./ssl.crt','./ssl.key'))