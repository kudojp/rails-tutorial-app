require 'test_helper'

class MicropostsInterfaceTest < ActionDispatch::IntegrationTest

  def setup
    @user = users(:michael)
    @no_micropost_user = users(:mallory)
    @one_micropost_user = users(:paul)
  end

  test "micropost interface" do
    log_in_as(@user)
    get root_path
    assert_select 'div.pagination'
    assert_select 'input[type="file"]'
    assert_match "#{ @user.microposts.count } microposts", response.body

    # 無効な送信
    assert_no_difference 'Micropost.count' do
      post microposts_path, params: { micropost: { content: "" }}
    end
    assert_select 'div#error_explanation'

    # 有効な送信
    content = "This micropost really ties the room together"
    picture = fixture_file_upload('test/fixtures/rails.png', 'image/png')
    assert_difference 'Micropost.count', 1 do
      post microposts_path, params: { micropost: { content: content, picture: picture }}
    end
    assert_redirected_to root_url
    follow_redirect!
    assert_match content, response.body
     

    # 投稿を削除する
    assert_select 'a', text: 'delete'
    first_micropost = @user.microposts.paginate(page: 1).first
    assert_difference 'Micropost.count', -1 do
      delete micropost_path(first_micropost)
    end


    # 違うユーザーのプロフィールにアクセス(削除リンクがないことを確認)
    get user_path(users(:archer))
    assert_select 'a', text: 'delete', count: 0
  end

  # micropostが０の時は複数形、１の時(checkできていない)は単数形になるべき。
  test "micropost count in a side-bar" do
    log_in_as(@no_micropost_user)
    get root_path
    assert_match "#{ @no_micropost_user.microposts.count } microposts", response.body
    
    log_in_as(@one_micropost_user)
    get root_path
    assert_match "#{ @one_micropost_user.microposts.count } micropost", response.body
    assert_no_match "#{ @one_micropost_user.microposts.count } microposts", response.body
  end

end
