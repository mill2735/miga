# @package MiGA
# @license Artistic-2.0

##
# Helper module including specific functions to add project results.
module MiGA::ProjectResult

  private

    ##
    # Internal alias for all add_result_*_distances.
    def add_result_distances(base)
      return nil unless result_files_exist?(base, %w[.Rdata .log .txt])
      r = Result.new(base + ".json")
      r.add_file(:rdata, "miga-project.Rdata")
      r.add_file(:matrix, "miga-project.txt")
      r.add_file(:log, "miga-project.log")
      r.add_file(:hist, "miga-project.hist")
      r
    end

    def add_result_clade_finding(base)
      return nil unless result_files_exist?(base,
        %w[.proposed-clades])
      return nil unless is_clade? or result_files_exist?(base,
        %w[.pdf .classif .medoids .class.tsv .class.nwk])
      r = add_result_iter_clades(base)
      r.add_file(:aai_tree,	"miga-project.aai.nwk")
      r.add_file(:proposal,	"miga-project.proposed-clades")
      r.add_file(:clades_aai90,	"miga-project.aai90-clades")
      r.add_file(:clades_ani95,	"miga-project.ani95-clades")
      r
    end

    def add_result_subclades(base)
      return nil unless result_files_exist?(base,
        %w[.pdf .classif .medoids .class.tsv .class.nwk])
      r = add_result_iter_clades(base)
      r.add_file(:ani_tree, "miga-project.ani.nwk")
      r
    end

    def add_result_iter_clades(base)
      r = Result.new(base + ".json")
      r.add_file(:report,	"miga-project.pdf")
      r.add_file(:class_table,	"miga-project.class.tsv")
      r.add_file(:class_tree,	"miga-project.class.nwk")
      r.add_file(:classif,	"miga-project.classif")
      r.add_file(:medoids,	"miga-project.medoids")
      r
    end

    def add_result_ogs(base)
      return nil unless result_files_exist?(base, %w[.ogs .stats])
      r = Result.new(base + ".json")
      r.add_file(:ogs, "miga-project.ogs")
      r.add_file(:stats, "miga-project.stats")
      r.add_file(:rbm, "miga-project.rbm")
      r
    end

    alias add_result_haai_distances add_result_distances
    alias add_result_aai_distances add_result_distances
    alias add_result_ani_distances add_result_distances
    alias add_result_ssu_distances add_result_distances

end