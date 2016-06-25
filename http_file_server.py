#!/usr/bin/env python
#coding:utf-8

from flask import Flask, request
import commands
import os, sys
print 'http file server version 0.0'
home = os.path.expanduser('~/books')
def init_app():
    global app
    app = Flask(__name__)

app = None

init_app()

_upload_file_form = u'''
<html>
<head>
<title>文件上传</title>
<meta name="viewport"
    content="width=device-width,initial-scale=1.0, minimum-scale=1.0,
    maximum-scale=1.0" />
    </head>
    <body>
        <div>
                <h1>上传文件</h1>
                        <form action="/upload"
                        method="post" enctype=multipart/form-data>
                                                                                                            <input type=file
                                                            name=file> <input
                                                            type=submit
                                                            value=上传>
                                                                    </form>
                                                                        </div>
                                                                        </body>
                                                                        </html>
'''

_DEBUG = lambda :__import__('pdb').set_trace()

@app.route('/')
def index():
    return _upload_file_form 

@app.route('/upload', methods=['POST'])
def upload_file():
    print len(request.files)
    #_DEBUG()
    if request.files :
        ufile = request.files['file']
        filepath = u'/'.join([home, ufile.filename])
        print u'save to {}'.format(filepath)
        ufile.save(filepath)
        return 'upload ok'
    else:
        return 'not file send!'

def ip():
    return commands.getoutput("ifconfig|grep 'inet addr'|tr -s '\t' ' '|cut -d ' ' -f"
        "3|cut -d ':' -f 2|grep -v '127'")

def _init_home():
    global home
    if len(sys.argv) > 1:
        home = os.path.expanduser(sys.argv[1])
    if not os.path.isdir(home):
        os.mkdir(home)
    print 'use home %s'%home
   
def run_server():
    print '======local ip======={}'.format(ip())
    _init_home()
    try:
        from gevent.wsgi import WSGIServer
        print 'use gevent server....'
        server = WSGIServer(('0.0.0.0', 5000), app)
        server.serve_forever()
    except ImportError:
        print 'gevent not exists, will use the flask server'
        app.run(host='0.0.0.0')

if __name__ == '__main__':
    run_server()
