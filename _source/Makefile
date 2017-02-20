# You must have jekyll and R installed, and they must be in PATH. For R, you
# need to install the servr package.

all:
  # kill $(ps aux | grep '[j]ekyll serve$' | awk '{print $2}')
	Rscript -e "servr::jekyll('..', command = 'jekyll build')"

clean:
	rm -r ../_site
