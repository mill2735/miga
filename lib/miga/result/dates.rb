
require "miga/result/base"

##
# Helper module including date-specific functions for results.
module MiGA::Result::Dates

  include MiGA::Result::Base
  
  ##
  # Returns the start date of processing as DateTime or +nil+ if it doesn't exist.
  def started_at
    date_at :start
  end

  ##
  # Returns the end (done) date of processing as DateTime or +nil+ if it doesn't exist.
  def done_at
    date_at :done
  end
  
  ##
  # Time it took for the result to complete as Float in minutes.
  def running_time
    a = started_at or return nil
    b = done_at or return nil
    (b - a).to_f * 24 * 60
  end


  private
    
    ##
    # Internal function to detect start and end dates
    def date_at(event)
      f = path event
      return nil unless File.size? f
      DateTime.parse File.read(f)
    end

end

