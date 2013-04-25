require "spec_helper"

class AcceptsPersistedBatchesController < ApplicationController
  include Hydra::Collections::AcceptsPersistedBatches
end

describe AcceptsPersistedBatchesController do
  
  before do
    request.env["HTTP_REFERER"] = "/"
    
    Rails.application.routes.draw do
      # add the route that you need in order to test
      match '/all' => "accepts_persisted_batches#all", :via => :put
      match '/add' => "accepts_persisted_batches#add", :via => :put
      
      # re-drawing routes means that you lose any routes you defined in routes.rb
      # so you have to add those back here if your controller references them
      # match '/login' => "sessions/new", :as => login
    end
  end
 
  after do
    # be sure to reload routes after the tests run
    Rails.application.reload_routes!
  end
  

  it "should respond to after_delete" do
    controller.respond_to? "after_delete"
  end
  it "should add items to list" do
    @mock_response = mock()
    @mock_document = mock()
    @mock_document2 = mock()
    @mock_document.stub(:export_formats => {})
    controller.stub(:get_solr_response_for_field_values => [@mock_response, [@mock_document, @mock_document2]])

    put :add, :id =>"77826928"
    session[:batch_document_ids].length.should == 1
    put :add, :id => "94120425"
    session[:batch_document_ids].length.should == 2
    session[:batch_document_ids].should include("77826928")
    get :index
    assigns[:documents].length.should == 2
    assigns[:documents].first.should == @mock_document
  end
  it "should delete an item from list" do
    put :add, :id =>"77826928"
    put :add, :id => "94120425"
    delete :destroy, :id =>"77826928"
    session[:batch_document_ids].length.should == 1
    session[:batch_document_ids].should_not include("77826928")
  end
  it "should clear list" do
    put :add, :id =>"77826928"
    put :add, :id => "94120425"
    put :clear
    session[:batch_document_ids].length.should == 0
  end

  it "should generate flash messages for normal requests" do
    put :add, :id => "77826928"
    flash[:notice].length.should_not == 0
  end
  it "should clear flash messages after xhr request" do
    xhr :put, :add, :id => "77826928"
    flash[:notice].should == nil
  end
  
  it "should check for empty" do
    put :add, :id =>"77826928"
    put :add, :id => "94120425"
    controller.check_for_empty?.should == false
    put :clear
    controller.check_for_empty?.should == true
  end


  describe "select all" do
    before do
      doc1 = stub(:id=>123)
      doc2 = stub(:id=>456)
      Hydra::Collections::SearchService.any_instance.should_receive(:last_search_documents).and_return([doc1, doc2])
      controller.stub(:current_user=>stub(:user_key=>'vanessa'))
    end
    it "should add every document in the current resultset to the batch" do
      put :all
      response.should redirect_to edit_batch_edits_path
      session[:batch_document_ids].should == [123, 456]
    end
    it "ajax should add every document in the current resultset to the batch but not redirect" do
      xhr :put, :all
      response.should_not redirect_to edit_batch_edits_path
      session[:batch_document_ids].should == [123, 456]
    end
  end

  describe "clear" do
    it "should clear the batch"
  end
end