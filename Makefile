LOG_FILE?=log

# Can be used like $(dir_guard) to ensure directory existence in a rule.
WIN_dir_guard=mkdir $(@D)
UNIX_dir_guard=mkdir -p $(@D)
dir_guard=$(WIN_dir_guard)

ifndef VERBOSE
LOG_OUTPUT_OPERATOR=>&
else
LOG_OUTPUT_OPERATOR=|& tee
endif

# Setting up paths to Abinit
ABINIT_DIR_PATH?=~/abinit
PSEUDO_POTENTIALS_DIR=$(ABINIT_DIR_PATH)/tests/Psps_for_tests
ABINIT_MAIN_DIR_PATH=$(ABINIT_DIR_PATH)/src/98_main

# Carbon pseudopotential files
CARBON_LDA_PAW_PSEUDO=$(PSEUDO_POTENTIALS_DIR)/6c_lda.paw
DEFAULT_CARBON_PSEUDO=$(CARBON_LDA_PAW_PSEUDO)

# Boron pseudopotential files
# Boron PAW LDA from http://users.wfu.edu/natalie/papers/pwpaw/periodictable/atoms/B/ 2017-06-30
BORON_PAW_LDA_PSEUDO=$(shell pwd)/B_LDA_abinit
BORON_Q3_PSEUDO=$(PSEUDO_POTENTIALS_DIR)/B-q3
BORON_HGH_PSEUDO=$(PSEUDO_POTENTIALS_DIR)/5b.3.hgh
DEFAULT_BORON_PSEUDO=$(BORON_PAW_LDA_PSEUDO)

# Nitrogen pseudopotential files
NITROGEN_MOD_PSEUDO=$(PSEUDO_POTENTIALS_DIR)/7n.1s.psp_mod
NITROGEN_PAW_PSEUDO=$(PSEUDO_POTENTIALS_DIR)/7n.paw
NITROGEN_HGH_PSEUDO=$(PSEUDO_POTENTIALS_DIR)/7n.psphgh
NITROGEN_NC_PSEUDO=$(PSEUDO_POTENTIALS_DIR)/7n.pspnc
DEFAULT_NITROGEN_PSEUDO=$(NITROGEN_PAW_PSEUDO)

# Applying default settings if not user-defined
BORON_PSEUDO?=$(DEFAULT_BORON_PSEUDO)
NITROGEN_PSEUDO?=$(DEFAULT_NITROGEN_PSEUDO)
CARBON_PSEUDO?=$(DEFAULT_CARBON_PSEUDO)

# Setting up paths to the automated parsing scripts
DEFAULT_TOOLS_PATH?=~/bin/abinit_parse_tools
PATH_TO_EIG_PARSER?=$(DEFAULT_TOOLS_PATH)/parse_band_eigenvalues.py
PATH_TO_DEN_PARSER?=~/bin/spacedToCSV.jar
PATH_TO_EIG_GRAPHER?=$(DEFAULT_TOOLS_PATH)/graph_band_eigenvalues.py
PATH_TO_ABINIT_INPUT_FILE_GENERATOR?=$(DEFAULT_TOOLS_PATH)/generate_abinit_input_file_from_json.py
PATH_TO_ABINIT_JSON_ATOM_GENERATOR?=$(DEFAULT_TOOLS_PATH)/convert_abinit_input_from_atoms_to_direct.py
PATH_TO_ABINIT_JSON_REPEATED_CELL_GENERATOR?=$(DEFAULT_TOOLS_PATH)/repeat_cell.py
PATH_TO_ABINIT_JSON_MERGER?=$(DEFAULT_TOOLS_PATH)/merge.py
PATH_TO_ABINIT_JSON_DOPED_CELL_GENERATOR?=$(DEFAULT_TOOLS_PATH)/dope_cell.py

TEMPFILE:=$(shell mktemp)

DOPED_CELLS_DIR:=doped_cells
PURE_CELLS_DIR:=pure_cells
CELL_REPETION_DIR:=cell_repetition_patterns
EXPERIMENT_TEMPLATE_DIR:=experiment_templates
DOPING_PATTERN_DIR:=doping_patterns


# default recipe. Will change frequently
all: geom

# Optimize the geometry to get the best value for acell
geom: hexBN_geom.out

# Make a .json file describing the band energy, to view with a plotting tool like Mathematica or MATLAB
band: hexBN_analysis.out hexBN_analysis_out.generic_DS2_band_eigen_energy.json hexBN_analysis.out hexBN_analysis_out.generic_DS2_band_eigen_energy.svg

# Make an .xsf file for the charge density of the lattice, to view in XCrysDen or VESTA
charge: hexBN_analysis.out hexBN_analysis_out.generic_DS1.xsf

%.in: %.abinit.json
	python $(PATH_TO_ABINIT_JSON_ATOM_GENERATOR) $^ | python $(PATH_TO_ABINIT_INPUT_FILE_GENERATOR) > $@

states: graphite_band.out

$(DOPED_CELLS_DIR)/%/formation_energy.abinit.json: $(DOPED_CELLS_DIR)/%/doped_cell.abinit.json $(EXPERIMENT_TEMPLATE_DIR)/formation_energy.abinit.json
	$(dir_guard)
	python $(PATH_TO_ABINIT_JSON_MERGER) $^ > $@

# dopings
$(DOPED_CELLS_DIR)/%_triangular/doped_cell.abinit.json: $(PURE_CELLS_DIR)/%.abinit.json $(DOPING_PATTERN_DIR)/triangular.abinit.json
	$(dir_guard)
	python $(PATH_TO_ABINIT_JSON_MERGER) $^ | python $(PATH_TO_ABINIT_JSON_DOPED_CELL_GENERATOR) > $@

# 2-D repetitions of unit cell
$(PURE_CELLS_DIR)/hexBN_%,0.abinit.json: $(PURE_CELLS_DIR)/hexBN_1,0.abinit.json $(CELL_REPETION_DIR)/xy_%x.abinit.json
	$(dir_guard)
	python $(PATH_TO_ABINIT_JSON_MERGER) $^ | python $(PATH_TO_ABINIT_JSON_REPEATED_CELL_GENERATOR) > $@

$(CELL_REPETION_DIR)/xy_%x.abinit.json:
	$(dir_guard)
	echo "{ \"meta\": {\"repeat_cell\": [ $(*), $(*), 1 ] } }" > $@

%.out: %.files %.in  #runs the test iff tbase%_x.out is older than tbase%_x.in or missing
	$(ABINIT_MAIN_DIR_PATH)/abinit < $< $(LOG_OUTPUT_OPERATOR) $(LOG_FILE)
	
%.files:
	echo $*.in > $@
	echo $*.out >> $@
	echo $*_in.generic >> $@
	echo $*_out.generic >> $@
	echo $*.generic >> $@
	echo $(BORON_PSEUDO) >> $@
	echo $(CARBON_PSEUDO) >> $@
	echo $(NITROGEN_PSEUDO) >> $@

%_band_eigen_energy.json: %_EIG
	python $(PATH_TO_EIG_PARSER) $^ > $@

%_band_eigen_energy.svg: %_band_eigen_energy.json
	python $(PATH_TO_EIG_GRAPHER) $^ > $@

%_3d_indexed.dat: %_DEN
	# cut3d only reads instructions from stdin, not arguments
	# Make only can handle single lines of text
	# So we use a temporary file to hold the text sent to cut3d
	echo $< > $(TEMPFILE)   # Tell cut3d which file to analyze
	echo 5 >> $(TEMPFILE)   # Tell cut3d to output 3d indexed data in columns
	echo $@ >> $(TEMPFILE)  # Tell cut3d the output file
	echo 0 >> $(TEMPFILE)   # Close cut3d
	$(ABINIT_MAIN_DIR_PATH)/cut3d < $(TEMPFILE)

# For use with arbitrary plotting tools, like MATLAB or Mathematica
%_3d_indexed.csv: %_3d_indexed.dat
	java -jar $(PATH_TO_DEN_PARSER) -in $< -out $@

# For use with files like XCrysDen or VESTA
%.xsf: %_DEN
	# cut3d only reads instructions from stdin, not arguments
	# Make only can handle single lines of text
	# So we use a temporary file to hold the text sent to cut3d
	echo $< > $(TEMPFILE)   # Tell cut3d which file to analyze
	echo 9 >> $(TEMPFILE)   # Tell cut3d to output xsf file format
	echo $@ >> $(TEMPFILE)  # Tell cut3d the output file
	echo "n" >> $(TEMPFILE) # Tell cut3d not to shift the axes
	echo 0 >> $(TEMPFILE)   # Close cut3d
	$(ABINIT_MAIN_DIR_PATH)/cut3d < $(TEMPFILE)	

clean: cleanLog cleanTemp cleanOutput

cleanOutput:
	rm -f *.out*

cleanLog:
	rm -f log

cleanTemp:
	rm -f *.generic*