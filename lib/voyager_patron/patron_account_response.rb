module VoyagerResponse
  class Amount
    include HappyMapper
    tag 'amount'
    namespace 'http://www.endinfosys.com/Voyager/myAccount'
    # Yes, Voyager has an element called 'amount' with a child element called 'amount'
    element :amount, Float, :tag => 'amount', :namespace => 'http://www.endinfosys.com/Voyager/myAccount'
  end

  class FineFee
    include HappyMapper
    tag 'fineFee'
    namespace 'http://www.endinfosys.com/Voyager/myAccount'
    has_one :amount, Amount
    element :posting_type, String, :tag => 'postingType', :namespace => 'http://www.endinfosys.com/Voyager/myAccount'
    element :title, String, :tag => 'title', :namespace => 'http://www.endinfosys.com/Voyager/myAccount'
  end

  class FinesFeesCluster
    include HappyMapper
    tag 'clusterFinesFees'
    namespace 'http://www.endinfosys.com/Voyager/myAccount'
    has_many :fines, FineFee
  end

  class FinesFees
    include HappyMapper
    tag 'finesFees'
    namespace 'http://www.endinfosys.com/Voyager/myAccount'
    element :title, String, :tag => 'title', :namespace => 'http://www.endinfosys.com/Voyager/myAccount'
    has_one :fines_fees_cluster, FinesFeesCluster
  end
  
  class RenewBlockInfo
    include HappyMapper
    tag 'blocks'
    namespace 'http://www.endinfosys.com/Voyager/myAccount'
    element :reason, String, :tag => 'blockReason', :namespace => 'http://www.endinfosys.com/Voyager/myAccount'
    element :count, String, :tag => 'blockCount', :namespace => 'http://www.endinfosys.com/Voyager/myAccount'
    element :code, String, :tag => 'blockCode', :namespace => 'http://www.endinfosys.com/Voyager/myAccount'
    element :limit, String, :tag => 'blockLimit', :namespace => 'http://www.endinfosys.com/Voyager/myAccount'
    element :display_message, String, :tag => 'blockDisplayName', :namespace => 'http://www.endinfosys.com/Voyager/myAccount'
  end
  
  class RenewStatus
    include HappyMapper
    tag 'renewStatus'
    namespace 'http://www.endinfosys.com/Voyager/myAccount'
    element :status, String, :tag => 'status', :namespace => 'http://www.endinfosys.com/Voyager/myAccount'
    has_one :block_info, RenewBlockInfo
  end

  class ChargedItem
    include HappyMapper
    tag 'chargedItem'
    namespace 'http://www.endinfosys.com/Voyager/myAccount'
    element :title, String, :tag => 'title', :namespace => 'http://www.endinfosys.com/Voyager/myAccount'
    element :location, String, :tag => 'location', :namespace => 'http://www.endinfosys.com/Voyager/myAccount'
    element :call_number, String, :tag => 'callNumber', :namespace => 'http://www.endinfosys.com/Voyager/myAccount'
    element :due_date, Time, :tag => 'dueDate', :namespace => 'http://www.endinfosys.com/Voyager/myAccount'
    element :item_type, String, :tag => 'itemType', :namespace => 'http://www.endinfosys.com/Voyager/myAccount'
    element :item_id, String, :tag => 'itemId', :namespace => 'http://www.endinfosys.com/Voyager/myAccount'
    element :status_code, Integer, :tag => 'statusCode', :namespace => 'http://www.endinfosys.com/Voyager/myAccount'
    has_one :renew_status, RenewStatus
    
    def status
      case self.status_code
      when 1 then 'Not Charged'
      when 2 then 'Charged'
      when 3 then 'Renewed'
      when 4 then 'Overdue'
      when 5 then 'Recall Request'
      when 6 then 'Hold Request'
      when 7 then 'On Hold'
      when 8 then 'In Transit'
      when 9 then 'In Transit Discharged'
      when 10 then 'In Transit On Hold'
      when 11 then 'Discharged'
      when 12 then 'Missing'
      when 13 then 'Lost--Library Applied'
      when 14 then 'Lost--System Applied'
      when 15 then 'Claims Returned'
      when 16 then 'Damaged'
      when 17 then 'Withdrawn'
      when 18 then 'At Bindery'
      when 19 then 'Cataloging Review'
      when 20 then 'Circulation Review'
      when 21 then 'Scheduled'
      when 22 then 'In Process'
      when 23 then 'Call Slip Request'
      when 24 then 'Short Loan Request'
      when 25 then 'Remote Storage Request'
      else 'Unknown'
      end
    end
  end
  
  class Library
    include HappyMapper
    tag 'cluster'
    namespace 'http://www.endinfosys.com/Voyager/myAccount'
    element :name, String, :tag => 'clusterName', :namespace => 'http://www.endinfosys.com/Voyager/myAccount'
    element :ub_id, String, :tag => 'ubSiteId', :namespace => 'http://www.endinfosys.com/Voyager/myAccount'
  end
  
  class LibraryCluster
    include HappyMapper
    tag 'clusterChargedItems'
    namespace 'http://www.endinfosys.com/Voyager/myAccount'
    has_one :library, Library
    has_many :charged_items, ChargedItem
  end
  
  class ChargedItemList
    include HappyMapper
    tag 'chargedItems'
    namespace 'http://www.endinfosys.com/Voyager/myAccount'
    has_many :library_clusters, LibraryCluster
  end
  
  class RequestedItem
    include HappyMapper
    tag 'requestItem'
    namespace 'http://www.endinfosys.com/Voyager/myAccount'
    element :title, String, :tag => 'itemTitle', :namespace => 'http://www.endinfosys.com/Voyager/myAccount'
    # the date is not always an expiration date as the XML implies
    element :date, Time, :tag => 'expireDate', :namespace => 'http://www.endinfosys.com/Voyager/myAccount'
    element :pickup_location, String, :tag => 'pickuplocation', :namespace => 'http://www.endinfosys.com/Voyager/myAccount'
    element :callslip_status_id, Integer, :tag => 'callslipStatus', :namespace => 'http://www.endinfosys.com/Voyager/myAccount'
    element :item_id, Integer, :tag => 'itemID', :namespace => 'http://www.endinfosys.com/Voyager/myAccount'
    element :hold_recall_id, Integer, :tag => 'holdRecallID', :namespace => 'http://www.endinfosys.com/Voyager/myAccount'
    element :hold_type, String, :tag => 'holdType', :namespace => 'http://www.endinfosys.com/Voyager/myAccount'
    element :db_key, String, :tag => 'dbKey', :namespace => 'http://www.endinfosys.com/Voyager/myAccount'
    element :ub_holdings_db_key, String, :tag => 'ubHoldingsDbKey', :namespace => 'http://www.endinfosys.com/Voyager/myAccount'
    element :queue_position, Integer, :tag => 'queuePosition', :namespace => 'http://www.endinfosys.com/Voyager/myAccount'
    element :status_id, Integer, :tag => 'status', :namespace => 'http://www.endinfosys.com/Voyager/myAccount'
    element :nofill_reason, String, :tag => 'nofillReason', :namespace => 'http://www.endinfosys.com/Voyager/myAccount'
    
    def request_status
      if self.hold_type == 'C'
        case self.callslip_status_id
        when 1 then 'Accepted'
        when 2 then 'Printed'
        when 3 then 'Reassigned'
        when 4 then 'Filled'
        when 5 then 'Not Filled'
        when 6 then 'Expired'
        when 7 then 'Cancelled'
        when 8 then 'Error'
        when 9 then 'Promoted'
        else 'Unknown'
        end
      elsif self.hold_type == 'H'
        case self.status_id
        when 1 then 'Filled'
        when 2 then 'Pending'
        when 3 then 'Cancelled'
        when 4 then 'Charged'
        when 5 then 'Expired'
        else 'Unknown'
        end       
      elsif self.hold_type == 'R'
        "Recall ##{self.queue_position}"
      else
        'Unknown'
      end
      
    end
  end
  
  class AvailableItem
    include HappyMapper
    tag 'availItem'
    namespace 'http://www.endinfosys.com/Voyager/myAccount'
    element :title, String, :tag => 'itemTitle', :namespace => 'http://www.endinfosys.com/Voyager/myAccount'
    # the date is not always an expiration date as the XML implies
    element :date, Time, :tag => 'expireDate', :namespace => 'http://www.endinfosys.com/Voyager/myAccount'
    element :pickup_location, String, :tag => 'pickuplocation', :namespace => 'http://www.endinfosys.com/Voyager/myAccount'
    element :item_id, Integer, :tag => 'itemID', :namespace => 'http://www.endinfosys.com/Voyager/myAccount'
    element :hold_recall_id, Integer, :tag => 'holdRecallID', :namespace => 'http://www.endinfosys.com/Voyager/myAccount'
    element :hold_type, String, :tag => 'holdType', :namespace => 'http://www.endinfosys.com/Voyager/myAccount'
    element :db_key, String, :tag => 'dbKey', :namespace => 'http://www.endinfosys.com/Voyager/myAccount'
    element :ub_holdings_db_key, String, :tag => 'ubHoldingsDbKey', :namespace => 'http://www.endinfosys.com/Voyager/myAccount'
    element :status_id, Integer, :tag => 'status', :namespace => 'http://www.endinfosys.com/Voyager/myAccount'
    
    def request_status
      case self.status_id
      when 1 then 'Active'
      when 2 then 'Pending'
      when 3 then 'Cancelled'
      when 4 then 'Charged'
      when 5 then 'Expired'
      else 'Unknown'
      end
    end
  end
  
  class BorrowingBlock
    include HappyMapper
    tag 'borrowingBlock'
    namespace 'http://www.endinfosys.com/Voyager/myAccount'
    element :reason, String, :tag => 'blockReason', :namespace => 'http://www.endinfosys.com/Voyager/myAccount'
    element :count, String, :tag => 'blockCount', :namespace => 'http://www.endinfosys.com/Voyager/myAccount'
    element :code, String, :tag => 'blockCode', :namespace => 'http://www.endinfosys.com/Voyager/myAccount'
    element :limit, String, :tag => 'blockLimit', :namespace => 'http://www.endinfosys.com/Voyager/myAccount'
    element :item_type, String, :tag => 'itemType', :namespace => 'http://www.endinfosys.com/Voyager/myAccount'
    element :patron_group_name, String, :tag => 'patronGroupName', :namespace => 'http://www.endinfosys.com/Voyager/myAccount'
    
    def explanation
      case self.reason.strip
      when 'Expired_patron' then "Your patron record has expired. Please contact the library for more information."
      when 'Address_expired_patron' then "The address in your patron record has expired. Please contact the library for more information."
      when 'Address_invalid_patron' then "The address in your patron record is invalid. Please contact the library for more information."
      when 'charge_limit_patron' then "You have #{self.count} items charged. The limit is #{self.limit}. Please contact the library for more information."
      when 'fine_limit_patron' then "You have #{self.count} in UW System Borrowing fines. The limit  is #{self.limit}."
      when 'odue_limit_patron' then "You have #{self.count} overdue items. The limit is #{self.limit}. Please contact the library for more information."
      when 'odue_recall_limit_patron' then "You have #{self.count} overdue recalled items. The limit is #{self.limit}. Please contact the library for more information."
      when 'recall_limit_patron' then "You have recalled #{self.count} items. The limit is #{self.limit}. Please contact the library for more information."
      when 'claims_ret_limit_patron' then "You have claimed to have returned #{self.count} items. The limit is #{self.limit}. Please contact the library for more information."
      when 'lost_limit_patron' then "You have #{self.count} declared lost items. The limit is #{self.limit}. Please contact the library for more information."
      when 'sshelved_limit_patron' then "You have #{self.count} self-shelved items. The limit is #{self.limit}. Please contact the library for more information."
      when 'short_loan_limit_patron' then "You have #{self.count} pending Short Loan requests. The limit is #{self.limit}. Please contact the library for more information."
      when 'call_slip_limit_patron' then "You have #{self.count} pending Book Retrieval requests. The limit is #{self.limit}. Please contact the library for more information."
      when 'suspension_patron' then "Your library privileges are blocked. Please contact the library for more information."
      when 'demerits_limit_patron' then "You have #{self.count} demerits. The limit is #{self.limit}. Please contact the library for more information."
      when 'ub_ineligible_patron' then "You are not eligible to use UW System Borrowing. Please contact the library for more information."
      when 'charge_limit_ub_patron' then "You have #{self.count} UW System Borrowing items charged. The limit is #{self.limit}. Please contact the library for more information."
      when 'fine_limit_ub_patron' then "You have #{self.count} in UW System Borrowing fines. The limit  is #{self.limit}."
      when 'odue_limit_ub_patron' then " You have #{self.count} UW System Borrowing overdue items. The limit is #{self.limit}. Please contact the library for more information."
      when 'odrecall_limit_ub_patron' then "You have #{self.count} UW System Borrowing recalled items. The limit is #{self.limit}. Please contact the library for more information."
      when 'claims_ret_limit_ub_patron' then "You have claimed to have returned #{self.count} UW System Borrowing items. The limit is #{self.limit}. Please contact the library for more information."
      when 'lost_limit_ub_patron' then "You have #{self.count} UW System Borrowing declared lost items. The limit is #{self.limit}. Please contact the library for more information."
      when 'sshelved_limit_ub_patron' then " You have #{self.count} UW System Borrowing self-shelved items. The limit is #{self.limit}. Please contact the library for more information."
      when 'request_limit_ub_patron' then "You have #{self.count} in UW System Borrowing requests. The limit  is #{self.limit}."
      when 'charge_limit_item_policy' then "You have #{self.count} items charged. The limit is #{self.limit}."
      when 'charge_limit_item_type' then "You have #{self.count} items charged. The limit is #{self.limit}."
      when 'charge_limit_item_policy_type' then "You have #{self.count} items charged. The limit is #{self.limit}."
      when 'demerits_limit_ub_patron' then "You have #{self.count} UW System Borrowing demerits. The limit is #{self.limit}. "
      else ""
      end
    end
      
  end
  
  class BlockCluster
    include HappyMapper
    tag 'clusterBorrowingBlocks'
    namespace 'http://www.endinfosys.com/Voyager/myAccount'
    has_one :library, Library
    has_many :borrowing_blocks, BorrowingBlock
  end
  
  class BorrowingBlockList
    include HappyMapper
    tag 'borrowingBlocks'
    namespace 'http://www.endinfosys.com/Voyager/myAccount'
    has_many :block_clusters, BlockCluster
  end

  class PatronAccount
    include HappyMapper
    tag 'serviceData'
    namespace 'http://www.endinfosys.com/Voyager/serviceParameters'
    has_one :fines_fees, FinesFees
    has_one :charged_item_list, ChargedItemList
    has_one :borrowing_block_list, BorrowingBlockList
    has_many :requested_items, RequestedItem
    has_many :available_items, AvailableItem
    
    def requested_items_and_available_items
      requested_items + available_items
    end
    
    def all_location_items
      location_items = {}
      self.charged_item_list.library_clusters.each do |library_cluster|
        library_cluster.charged_items.each do |charged_item|
          location_items["#{library_cluster.library.ub_id.gsub(/^1@/,'')}::#{charged_item.item_id}"] = "Checked Out to You"
        end
      end
      self.requested_items.each do |requested_item|
        location_items["#{requested_item.db_key.gsub(/^1@/,'')}::#{requested_item.item_id}"] = "Requested by You"
      end
      self.available_items.each do |available_item|
        location_items["#{available_item.db_key.gsub(/^1@/,'')}::#{available_item.item_id}"] = "Available for Pickup"
      end
      location_items
    end
  end
end