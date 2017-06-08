# Simulation of Graphite using Abinit
This project uses a program called [Abinit](http://www.abinit.org/) to simulate a mono-layer graphite lattice using ab-inito principles. The goals of this project are as follows:

- Gain familiarity with the Abinit program
- Determine the band energies of graphite
- Determine the charge density of graphite
- Determine the state density of graphite

This project was written for the laboratory of Jun Namakura (中村) at the University of Electrocommunications (電気通信大学) in Tokyo (東京都), Japan (日本).

## Contributing
The main point of this project is for me to do the work myself, but I'm always happy to get feedback. At present, I will not be accepting pull requests, but please feel free to submit an Issue on GitHub.

## License
See [LICENSE.md](LICENSE.md).

## Requirements
This program uses the following programs:

- [Abinit](http://www.abinit.org/) to perform the simulation, assumed to be in the user's $PATH as `abinit`
- [python](https://www.python.org/) version 2 to execute various custom analysis scripts, assumed to the user's $PATH as `python`
- `parse_band_eigenvalues.py` to convert `_EIG` files into more-easily readable [JSON](http://www.json.org/) form for analysis
- [Wolfram Mathematica](https://www.wolfram.com/mathematica/) to execute various `.nb` files for analysis of the data
- [GNU Make](https://www.gnu.org/software/make/) to execute the Makefile that automatically runs the above programs. It is, of course, still possible to run this project without Make, but very tedious.

## Use
### Makefile
Most of the program has been set up to run via a [Makefile](Makefile). The following commands are used (note that `%` refers to a wildcard string):

- `geom` optimize the geometry of the graphite cell
- `band` determine the band energy eigenstates of the graphite cell
- `%.out` run the experiment `%.in` and output the results to `%.out`. Errors are reported to `log`
- `%.files` generates a file with the command-line user input to `abinit` for the experiment `%.in`
- `%_band_eigen_energy.json` uses the python script `parse_band_eigenvalues.py` to parse `%_EIG` and output it in more-readable `JSON` format.
- `clean` executes `cleanLog` and `cleanTemp`
- `cleanTemp` removes all files with `.generic` in the file name
- `cleanLog` removes the log
- `cleanAllOut` removes all files with `.out` in the file name

If the `VERBOSE` variable is specified, `abinit` experiment outputs will be copied to stdout

## To-do
- Calculate charge density
- Calculate state density
- Add link to `parse_band_eigenvalues.py`