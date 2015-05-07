#!/usr/bin/python
#coding:utf-8

from flask import Flask, request
import commands

print 'http file server version 0.0'

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
        filepath = '/'.join(['', 'tmp', ufile.filename])
        print 'save to {}'.format(filepath)
        ufile.save(filepath)
        return 'upload ok'
    else:
        return 'not file send!'

def ip():
    return commands.getoutput("ifconfig|grep 'inet addr'|tr -s '\t' ' '|cut -d ' ' -f"
        "3|cut -d ':' -f 2|grep -v '127'")

if __name__ == '__main__':
    print '======local ip======={}'.format(ip())
    app.run(host='0.0.0.0')
