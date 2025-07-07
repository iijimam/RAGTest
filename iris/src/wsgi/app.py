from flask import Flask,request, jsonify,make_response
import iris
import json
import os

import vectorutils

from flask_restx import Api, Resource, fields

from werkzeug.utils import secure_filename
BASE_DIR = os.path.dirname(os.path.abspath(__file__))
UPLOAD_FOLDER = os.path.join(BASE_DIR, 'uploaded_images')
# フォルダがなければ作成
os.makedirs(UPLOAD_FOLDER, exist_ok=True)

app = Flask(__name__)
api = Api(app, version='1.0', title='試しのアプリケーション', description='ファイルアップロード用API')  # <- タイトルなどを変更


@api.representation('application/json')
def output_json_utf8(data, code, headers=None):
    resp = make_response(json.dumps(data, ensure_ascii=False), code)
    resp.headers.extend(headers or {})
    resp.headers['Content-Type'] = 'application/json; charset=utf-8'
    return resp

# モデル定義（レスポンスなどに使用）
response_model = api.model("ResponseModel", {
    "FishName": fields.String(description="魚の名前"),
    "FishInfo": fields.String(description="魚の情報"),
})

# ------------------------------------------
# /hello エンドポイント
# ------------------------------------------
@api.route('/hello')
class Hello(Resource):
    @api.doc(description="挨拶を返すテスト用エンドポイント")
    def get(self):
        modori = vectorutils.hello()
        return modori, 200


# ------------------------------------------
# /upload エンドポイント
# ------------------------------------------
upload_parser = api.parser()
upload_parser.add_argument('fish', location='files',
                           type='FileStorage', required=True, help='魚の画像ファイル')

@api.route('/upload')
@api.expect(upload_parser)
class Upload(Resource):
    @api.doc(description="画像ファイルをアップロードし、類似魚をベクトル検索")
    @api.response(200, 'Success', response_model)
    def post(self):
        file = request.files['fish']
        filefullpath = os.path.join(UPLOAD_FOLDER, secure_filename(file.filename))
        file.save(filefullpath)

        modori = vectorutils.searchVec(filefullpath)
        return modori, 200


if __name__ == "__main__":
    app.run(host="0.0.0.0",port=8080,debug=True)