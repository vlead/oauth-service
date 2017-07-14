from flask import Flask, redirect, url_for, session, request, jsonify, abort
import requests
import requests

from requests.packages.urllib3.exceptions import InsecureRequestWarning
requests.packages.urllib3.disable_warnings(InsecureRequestWarning)

app = Flask(__name__)
app.debug = True    
app.secret_key = 'development'
app.config['SESSION_COOKIE_NAME']="Client"

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
    return jsonify(data=data)

@app.route('/')
def index():
    return check_login()

    if 'token' in session:
        ret = remote.get('email')
        return jsonify(ret.data)
    return redirect(url_for('login'))

@app.route('/login')
def login():
    return remote.authorize(callback=url_for('authorized', _external=True))

@app.route('/logout')
def logout():
    session.pop('dev_token', None)
    return redirect(url_for('index'))

@app.route('/authorized')
def authorized():
    resp = remote.authorized_response()
    if resp is None:
        return 'Access denied: error=%s' % (
            request.args['error']
        )
    if isinstance(resp, dict) and 'access_token' in resp:
        session['dev_token'] = (resp['access_token'], '')
        return jsonify(resp)
    return jsonify(resp=str(resp))

@app.route('/client')
def client_method():
    ret = remote.get("client")
    if ret.status not in (200, 201):
        return abort(ret.status)
    return ret.raw_data

@app.route('/address')
def address():
    ret = remote.get('address/hangzhou')
    if ret.status not in (200, 201):
        return ret.raw_data, ret.status
    return ret.raw_data

@app.route('/method/<name>')
def method(name):
    func = getattr(remote, name)
    ret = func('method')
    return ret.raw_data

if __name__ == '__main__':
    app.run(host='localhost', port=8000,ssl_context=('./ssl.crt','./ssl.key'))