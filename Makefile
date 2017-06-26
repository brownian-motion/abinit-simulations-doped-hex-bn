LOG_FILE?=log

ifndef VERBOSE
LOG_OUTPUT_OPERATOR=>&
else
LOG_OUTPUT_OPERATOR=|& tee
endif

ABINIT_DIR_PATH?=~/abinit
PSEUDO_POTENTIALS_DIR=$(ABINIT_DIR_PATH)/tests/Psps_for_tests
ABINIT_MAIN_DIR_PATH=$(ABINIT_DIR_PATH)/src/98_main

CARBON_LDA_PSEUDO=$(PSEUDO_POTENTIALS_DIR)/6c_lda.paw
DEFAULT_CARBON_PSEUDO=$(CARBON_LDA_PSEUDO)
CARBON_PSEUDO?=$(DEFAULT_CARBON_PSEUDO)

PATH_TO_EIG_PARSER?=~/bin/parse_band_eigenvalues.py
PATH_TO_DEN_PARSER?=~/bin/spacedToCSV.jar

TEMPFILE:=$(shell mktemp)

all: charge

# Optimize the geometry to get the best value for acell
geom: graphite_geom.out #so it just checks the version/timestamp of tbase1_1.out relative to tbase1_x.files

# Make a .json file describing the band energy, to view with a plotting tool like Mathematica or MATLAB
band: graphite_band.out graphite_band_out.generic_DS2_band_eigen_energy.json

# Make an .xsf file for the charge density of the lattice, to view in XCrysDen or VESTA
charge: graphite_band.out graphite_band_out.generic_DS1.xsf

states: graphite_band.out

%.out: %.files %.in  #runs the test iff tbase%_x.out is older than tbase%_x.in or missing
	$(ABINIT_MAIN_DIR_PATH)/abinit < $< $(LOG_OUTPUT_OPERATOR) $(LOG_FILE)
	
%.files:
	echo $*.in > $@
	echo $*.out >> $@
	rm -f *.out*
	echo $*_in.generic >> $@
	echo $*_out.generic >> $@
	echo $*.generic >> $@
	echo $(CARBON_PSEUDO) >> $@

%_band_eigen_energy.json: %_EIG
	python $(PATH_TO_EIG_PARSER) $^ > $@

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