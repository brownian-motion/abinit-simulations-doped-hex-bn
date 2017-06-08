LOG_FILE?=log

ifndef VERBOSE
LOG_OUTPUT_OPERATOR=>&
else
LOG_OUTPUT_OPERATOR=|& tee
endif

PSEUDO_POTENTIALS_DIR=~/abinit/tests/Psps_for_tests

GRAPHITE_PSEUDO=6c.pspnc

DEFAULT_PSEUDO=$(GRAPHITE_PSEUDO)

all: band

geom: graphite_geom.out #so it just checks the version/timestamp of tbase1_1.out relative to tbase1_x.files

band: graphite_band.out graphite_band_out.generic_DS2_band_eigen_energy.json

%.out: %.files %.in  #runs the test iff tbase%_x.out is older than tbase%_x.in or missing
	abinit < $< $(LOG_OUTPUT_OPERATOR) $(LOG_FILE)
	
%.files:
	echo $*.in > $@
	echo $*.out >> $@
	echo $*_in.generic >> $@
	echo $*_out.generic >> $@
	echo $*.generic >> $@
	echo $(PSEUDO_POTENTIALS_DIR)/$(DEFAULT_PSEUDO) >> $@

%_band_eigen_energy.json: %_EIG
	python ~/bin/parse_band_eigenvalues.py $^ > $@

clean: cleanLog cleanTemp

cleanOutput:
	rm -f *.out

cleanLog:
	rm -f log

cleanTemp:
	rm -f *.generic*

cleanAllOut:
	rm -f *.out*