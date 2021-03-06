# @package MiGA
# @license Artistic-2.0

##
# Helper module including specific functions handle datasets.
module MiGA::Project::Dataset
  

  ##
  # Returns Array of MiGA::Dataset.
  def datasets
    metadata[:datasets].map{ |name| dataset(name) }
  end

  ##
  # Returns Array of String (without evaluating dataset objects).
  def dataset_names
    metadata[:datasets]
  end
  
  ##
  # Returns MiGA::Dataset.
  def dataset(name)
    name = name.miga_name
    return nil unless MiGA::Dataset.exist?(self, name)
    @datasets ||= {}
    @datasets[name] ||= MiGA::Dataset.new(self, name)
    @datasets[name]
  end

  ##
  # Iterate through datasets, with one or two variables passed to +blk+.
  # If one, the dataset MiGA::Dataset object is passed. If two, the name and
  # the dataset object are passed.
  def each_dataset(&blk)
    metadata[:datasets].each do |name|
      if blk.arity == 1
        blk.call(dataset(name))
      else
        blk.call(name, dataset(name))
      end
    end
  end
  
  ##
  # Add dataset identified by +name+ and return MiGA::Dataset.
  def add_dataset(name)
    unless metadata[:datasets].include? name
      MiGA::Dataset.new(self, name)
      @metadata[:datasets] << name
      save
    end
    dataset(name)
  end
  
  ##
  # Unlink dataset identified by +name+ and return MiGA::Dataset.
  def unlink_dataset(name)
    d = dataset(name)
    return nil if d.nil?
    self.metadata[:datasets].delete(name)
    save
    d
  end
  
  ##
  # Import the dataset +ds+, a MiGA::Dataset, using +method+ which is any method
  # supported by File#generic_transfer.
  def import_dataset(ds, method=:hardlink)
    raise "Impossible to import dataset, it already exists: #{ds.name}." if
      MiGA::Dataset.exist?(self, ds.name)
    # Import dataset results
    ds.each_result do |task, result|
      # import result files
      result.each_file do |file|
        File.generic_transfer("#{result.dir}/#{file}",
          "#{path}/data/#{MiGA::Dataset.RESULT_DIRS[task]}/#{file}", method)
      end
      # import result metadata
      %w(json start done).each do |suffix|
        if File.exist? "#{result.dir}/#{ds.name}.#{suffix}"
          File.generic_transfer("#{result.dir}/#{ds.name}.#{suffix}",
            "#{path}/data/#{MiGA::Dataset.RESULT_DIRS[task]}/" +
	                      "#{ds.name}.#{suffix}", method)
        end
      end
    end
    # Import dataset metadata
    File.generic_transfer("#{ds.project.path}/metadata/#{ds.name}.json",
      "#{self.path}/metadata/#{ds.name}.json", method)
    # Save dataset
    self.add_dataset(ds.name)
  end

  ##
  # Find all datasets with (potential) result files but are yet unregistered.
  def unregistered_datasets
    datasets = []
    MiGA::Dataset.RESULT_DIRS.values.each do |dir|
      dir_p = "#{path}/data/#{dir}"
      next unless Dir.exist? dir_p
      Dir.entries(dir_p).each do |file|
        next unless
          file =~ %r{
            \.(fa(a|sta|stqc?)?|fna|solexaqa|gff[23]?|done|ess)(\.gz)?$
          }x
        m = /([^\.]+)/.match(file)
        datasets << m[1] unless m.nil? or m[1] == "miga-project"
      end
    end
    datasets.uniq - metadata[:datasets]
  end
  
  ##
  # Are all the datasets in the project preprocessed? Save intermediate results
  # if +save+ (until the first incomplete dataset is reached).
  def done_preprocessing?(save=true)
    dataset_names.each do |dn|
      ds = dataset(dn)
      return false if ds.is_ref? and not ds.done_preprocessing?(save)
    end
    true
  end

  ##
  # Returns a two-dimensional matrix (Array of Array) where the first index
  # corresponds to the dataset, the second index corresponds to the dataset
  # task, and the value corresponds to:
  # - 0: Before execution.
  # - 1: Done (or not required).
  # - 2: To do.
  def profile_datasets_advance
    advance = []
    self.each_dataset_profile_advance do |ds_adv|
      advance << ds_adv
    end
    advance
  end

  ##
  # Call +blk+ passing the result of MiGA::Dataset#profile_advance for each
  # registered dataset.
  def each_dataset_profile_advance(&blk)
    each_dataset { |ds| blk.call(ds.profile_advance) }
  end
  
end

