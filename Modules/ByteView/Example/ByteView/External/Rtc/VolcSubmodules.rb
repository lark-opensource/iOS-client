class VolcSubmodules
    @@submodules = []

    def self.get
        @@submodules
    end

    def self.set(modules)
        @@submodules = modules
    end
end
