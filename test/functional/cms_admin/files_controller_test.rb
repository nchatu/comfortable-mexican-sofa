require File.expand_path('../../test_helper', File.dirname(__FILE__))

class CmsAdmin::FilesControllerTest < ActionController::TestCase
  
  def test_get_index
    get :index, :site_id => cms_sites(:default)
    assert_response :success
    assert assigns(:files)
    assert_template :index
  end
  
  def test_get_index_with_no_files
    Cms::File.delete_all
    get :index, :site_id => cms_sites(:default)
    assert_response :redirect
    assert_redirected_to :action => :new
  end
  
  def test_get_index_with_category
    get :index, :site_id => cms_sites(:default), :category => cms_categories(:default).label
    assert_response :success
    assert assigns(:files)
    assert_equal 1, assigns(:files).count
    assert assigns(:files).first.categories.member? cms_categories(:default)
  end
  
  def test_get_index_with_category_invalid
    get :index, :site_id => cms_sites(:default), :category => 'invalid'
    assert_response :success
    assert assigns(:files)
    assert_equal 0, assigns(:files).count
  end
  
  def test_get_new
    site = cms_sites(:default)
    get :new, :site_id => site
    assert_response :success
    assert assigns(:file)
    assert_template :new
    assert_select "form[action=/cms-admin/sites/#{site.id}/files][enctype=multipart/form-data]"
  end
  
  def test_get_edit
    file = cms_files(:default)
    get :edit, :site_id => file.site, :id => file
    assert_response :success
    assert assigns(:file)
    assert_template :edit
    assert_select "form[action=/cms-admin/sites/#{file.site.id}/files/#{file.id}]"
  end
  
  def test_get_edit_failure
    get :edit, :site_id => cms_sites(:default), :id => 'not_found'
    assert_response :redirect
    assert_redirected_to :action => :index
    assert_equal 'File not found', flash[:error]
  end
  
  def test_create
    assert_difference 'Cms::File.count' do
      post :create, :site_id => cms_sites(:default), :file => {
        :label        => 'Test File',
        :description  => 'Test Description',
        :file         => [fixture_file_upload('files/image.jpg', "image/jpeg")]
      }
      assert_response :redirect
      file = Cms::File.last
      assert_equal cms_sites(:default), file.site
      assert_equal 'Test File', file.label
      assert_equal 'Test Description', file.description
      assert_redirected_to :action => :edit, :id => file
      assert_equal 'Files uploaded', flash[:notice]
    end
  end
  
  def test_create_failure
    assert_no_difference 'Cms::File.count' do
      post :create, :site_id => cms_sites(:default), :file => { }
      assert_response :success
      assert_template :new
      assert_equal 'Failed to upload files', flash[:error]
    end
  end
  
  def test_create_multiple
    Cms::File.delete_all
    
    assert_difference 'Cms::File.count', 2 do
      post :create, :site_id => cms_sites(:default), :file => {
        :label        => 'Test File',
        :description  => 'Test Description',
        :file         => [
          fixture_file_upload('files/image.jpg', "image/jpeg"),
          fixture_file_upload('files/image.gif', "image/gif")
        ]
      }
      assert_response :redirect
      file_a, file_b = Cms::File.all
      assert_equal cms_sites(:default), file_a.site
      
      assert_equal 'image.jpg', file_a.file_file_name
      assert_equal 'image.gif', file_b.file_file_name
      assert_equal 'Test File 1', file_a.label
      assert_equal 'Test File 2', file_b.label
      assert_equal 'Test Description', file_a.description
      assert_equal 'Test Description', file_b.description
      
      assert_redirected_to :action => :edit, :id => file_b
      assert_equal 'Files uploaded', flash[:notice]
    end
  end
  
  def test_create_as_xhr
    request.env['HTTP_X_FILE_NAME'] = 'image.jpg'
    request.env['CONTENT_TYPE'] = 'image/jpeg'
    request.env['RAW_POST_DATA'] = File.open(File.expand_path('../../fixtures/files/image.jpg', File.dirname(__FILE__)))
    
    assert_difference 'Cms::File.count' do
      xhr :post, :create, :site_id => cms_sites(:default)
      assert_response :success
      
      file = Cms::File.last
      assert_equal 'image.jpg', file.file_file_name
      assert_equal 'image/jpeg', file.file_content_type
    end
  end
  
  def test_update
    file = cms_files(:default)
    put :update, :site_id => file.site, :id => file, :file => {
      :label        => 'New File',
      :description  => 'New Description'
    }
    assert_response :redirect
    assert_redirected_to :action => :edit, :site_id => file.site, :id => file
    assert_equal 'File updated', flash[:notice]
    file.reload
    assert_equal 'New File', file.label
    assert_equal 'New Description', file.description
  end
  
  def test_update_failure
    file = cms_files(:default)
    put :update, :site_id => file.site, :id => file, :file => {
      :file         => nil
    }
    assert_response :success
    assert_template :edit
    file.reload
    assert_not_equal nil, file.file
    assert_equal 'Failed to update file', flash[:error]
  end
  
  def test_destroy
    assert_difference 'Cms::File.count', -1 do
      delete :destroy, :site_id => cms_sites(:default), :id => cms_files(:default)
      assert_response :redirect
      assert_redirected_to :action => :index
      assert_equal 'File deleted', flash[:notice]
    end
  end
  
  def test_destroy_as_xhr
    assert_difference 'Cms::File.count', -1 do
      xhr :delete, :destroy, :site_id => cms_sites(:default), :id => cms_files(:default)
      assert_response :success
    end
  end
  
  def test_reorder
    file_one = cms_files(:default)
    file_two = cms_sites(:default).files.create(
      :file => fixture_file_upload('files/image.jpg', "image/jpeg")
    )
    assert_equal 0, file_one.position
    assert_equal 1, file_two.position

    put :reorder, :site_id => cms_sites(:default), :cms_file => [file_two.id, file_one.id]
    assert_response :success
    file_one.reload
    file_two.reload

    assert_equal 1, file_one.position
    assert_equal 0, file_two.position
  end
  
end
