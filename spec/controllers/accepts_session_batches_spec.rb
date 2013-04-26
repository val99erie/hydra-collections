require "spec_helper"

class AcceptsSessionBatchesController < ApplicationController
  include Hydra::Collections::AcceptsSessionBatches
end

describe AcceptsSessionBatchesController do
  
  def with_batches_routing
    with_routing do |map|
      map.draw do
        match '/index' => "accepts_session_batches#index", :via => :put
        match '/useall' => "accepts_session_batches#all", :via => :put
        match '/add' => "accepts_session_batches#add", :via => :put
        match '/clear' => "accepts_session_batches#clear", :via => :put
        match '/:id' => "accepts_session_batches#destroy", :via => :delete
      end
      yield
    end
  end
  
  before(:each) do
    request.env["HTTP_REFERER"] = "/"
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
    
    with_batches_routing do
      put :add, :id =>"77826928"
      session[:batch_document_ids].length.should == 1
      put :add, :id => "94120425"
      session[:batch_document_ids].length.should == 2
      session[:batch_document_ids].should include("77826928")
      # get :index
      # assigns[:documents].length.should == 2
      # assigns[:documents].first.should == @mock_document
    end
  end
  it "should delete an item from list" do
    with_batches_routing do
      put :add, :id =>"77826928"
      put :add, :id => "94120425"
      delete :destroy, :id =>"77826928"
    end
    session[:batch_document_ids].length.should == 1
    session[:batch_document_ids].should_not include("77826928")
  end
  it "should clear list" do
    with_batches_routing do
      put :add, :id =>"77826928"
      put :add, :id => "94120425"
      put :clear
    end
    session[:batch_document_ids].length.should == 0
  end

  it "should generate flash messages for normal requests" do
    with_batches_routing do
      put :add, :id => "77826928"
    end
    flash[:notice].length.should_not == 0
  end
  it "should clear flash messages after xhr request" do
    with_batches_routing do
      xhr :put, :add, :id => "77826928"
    end
    flash[:notice].should == nil
  end
  
  it "should check for empty" do
    with_batches_routing do
      put :add, :id =>"77826928"
      put :add, :id => "94120425"
      controller.check_for_empty?.should == false
      put :clear
    end
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
      with_batches_routing do
        put :all
      end
      # response.should redirect_to :back
      response.should be_redirect
      session[:batch_document_ids].should == [123, 456]
    end
    it "ajax should add every document in the current resultset to the batch but not redirect" do
      with_batches_routing do
        xhr :put, :all
      end
      response.should be_successful
      session[:batch_document_ids].should == [123, 456]
    end
  end

  describe "clear" do
    it "should clear the batch"
  end
end