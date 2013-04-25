module Hydra
  module Collections
    module AcceptsPersistedBatches
      extend ActiveSupport::Concern

      included do
        before_filter :filter_docs_with_access!, :only=>[:edit, :update, :destroy_collection]
        before_filter :check_for_empty!, :only=>[:edit, :update, :destroy_collection]
      end


      # fetch the documents that match the ids in the folder
      def index
        @response, @documents = get_solr_response_for_field_values("id", batch)
      end

      # add a document_id to the batch. :id of action is solr doc id 
      def add
        id = params[:id]
        raise "Too many items in batch!" if ((batch.to_s.length+id.to_s.length) > 2200) # we are going to overflow our cookie
        batch << id if ! batch.include? id 
        respond_to do |format|
          format.html do
            redirect_to :back, :notice =>  "#{params[:title] || "Item"} successfully added to batch"
          end
          format.js { render :json => batch }
        end
      end

      # remove a document_id from the batch. :id of action is solr_doc_id
      def destroy
        batch.delete(params[:id])
        respond_to do |format|
          format.html do
            redirect_to :back, :notice => "#{params[:title] || "Item"} successfully removed from batch"
          end
          format.js do
            render :json => {"OK" => "OK"}
          end
        end

      end

      # get rid of the items in the batch
      def clear
        clear_batch!
        respond_to do |format|
          format.html { redirect_to :back, :notice=> "Batch has been cleared" }
          format.js { render :json => batch }
        end
      end

      def all 
        self.batch = Hydra::BatchEdit::SearchService.new(session, current_user.user_key).last_search_documents.map(&:id)
        respond_to do |format|
          format.html { redirect_to edit_batch_edits_path }
          format.js { render :json => batch }
        end
      end

      def check_for_empty?
        return batch.empty?
      end

      protected

      def batch
        session[:batch_document_ids] ||= []
      end

      def batch=(val)
        session[:batch_document_ids] = val
      end


      def clear_batch!
        self.batch = []
      end

      def check_for_empty!
        if batch.empty?
          redirect_to :back
          return false
        end
      end

      def filter_docs_with_read_access!
        filter_docs_with_access!(:read)
      end

      def filter_docs_with_edit_access!
        filter_docs_with_access!(:edit)
      end

      def filter_docs_with_access!(access_type=:edit)
        no_permissions = []
        if batch.empty?
          flash[:notice] = "Select something first"
        else
          batch.dup.each do |doc_id|
            unless can?(access_type, doc_id)
              session[:batch_document_ids].delete(doc_id)
              no_permissions << doc_id
            end
          end
          flash[:notice] = "You do not have permission to edit the documents: #{no_permissions.join(', ')}" unless no_permissions.empty?
        end
      end
    end
  end
end