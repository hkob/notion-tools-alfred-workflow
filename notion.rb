require "net/http"
require "uri"
require "json"
require "date"

# Read environments
MY_NOTION_TOKEN = ENV["MY_NOTION_TOKEN"] # Notion token
TASK_ID = ENV["TASK_ID"] # タスクのデータベースID
PROJECT_ID = ENV["PROJECT_ID"] # プロジェクトのデータベースID
TASK_NAME = ENV["TASK_NAME"] # タスクの名前
TASK_DATE = ENV["TASK_DATE"] # タスクの日付
TASK_DONE = ENV["TASK_DONE"] # タスクの終了フラグ
PROJECT_NAME = ENV["PROJECT_NAME"] # プロジェクトの名前
PROJECT_LINK_NAME = ENV["PROJECT_LINK_NAME"] # タスクからのリンク名
REFLECTION_TITLE=ENV["REFLECTION_TITLE"] # 振り返りのタスクタイトル
TASK_POMO = ENV["TASK_POMO"] # ポモドーロの属性
TASK_IS_POMO = ENV["TASK_IS_POMO"] || "" # ポモドーロであるときに true になる属性
TASK_IS_NOT_POMO = ENV["TASK_IS_NOT_POMO"] || "" # ポモドーロでないときに true になる属性
MY_TZ=ENV["MY_TZ"] # タイムゾーン

# post 専用のメソッド
def post_notion(uri, payload)
  request = Net::HTTP::Post.new(uri)
  request.content_type = "application/json"
  request["Authorization"] = "Bearer #{MY_NOTION_TOKEN}"
  request["Notion-Version"] = "2021-05-13"
  request.body = JSON.dump(payload)
  response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
    http.request(request)
  end
  code = response.code
  unless code == "200"
    STDERR.print "Error!\n#{response.body}\n" # エラーの時だけエラーを表示する
  end
  STDERR.print response.body
  JSON.parse(response.body)["results"]
end

def create_task(title, datetime, project_id = nil)
  relation = project_id ? [{id: "#{project_id}"}] : []
  post_notion URI.parse("https://api.notion.com/v1/pages"), {
    parent: {
      database_id: TASK_ID
    },
    properties: {
      TASK_NAME => {
        title: [
          {
            text: {
              content: title
            }
          }
        ]
      },
      TASK_DATE => {
        type: "date",
        date: {
          start: datetime
        }
      },
      PROJECT_LINK_NAME => {
        type: "relation",
        relation: relation
      }
    }
  }
end

# ページの取得
def get_notion_pages(payload, database_id = TASK_ID)
  post_notion URI.parse("https://api.notion.com/v1/databases/#{database_id}/query"), payload
end

# patch 専用のメソッド
def patch_notion(uri, payload)
  request = Net::HTTP::Patch.new(uri)
  request.content_type = "application/json"
  request["Authorization"] = "Bearer #{MY_NOTION_TOKEN}"
  request["Notion-Version"] = "2021-05-13"
  request.body = JSON.dump(payload)
  response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
    http.request(request)
  end
  code = response.code
  unless code == "200"
    STDERR.print "Error!\n#{response.body}\n" # エラーの時だけエラーを表示する
  end
end

# block 要素を追加するメソッド
def append_block_children(id, payload)
  patch_notion URI.parse("https://api.notion.com/v1/blocks/#{id}/children"), payload
end

# page プロパティを更新するメソッド
def update_page(id, payload)
  patch_notion URI.parse("https://api.notion.com/v1/pages/#{id}"), payload
end
