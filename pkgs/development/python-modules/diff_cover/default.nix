{ stdenv, buildPythonPackage, fetchPypi
, inflect
, jinja2
, jinja2_pluralize
, pygments
, six
# test dependencies
, coverage
, flake8
, mock
, nose
, pycodestyle
, pyflakes
, pylint
, pytest
}:

buildPythonPackage rec {
  pname = "diff_cover";
  version = "2.3.0";

  preCheck = ''
    export LC_ALL=en_US.UTF-8;
  '';

  src = fetchPypi {
    inherit pname version;
    sha256 = "1kfv5icvnljh9c97i3fykh0zlba1zjz0rb3p9x06hdwh25n81915";
  };

  propagatedBuildInputs = [ jinja2 jinja2_pluralize pygments six inflect ];

  checkInputs = [ mock coverage pytest nose pylint pyflakes pycodestyle ];

  # ignore tests which try to write files
  checkPhase = ''
    pytest -k 'not added_file_pylint_console and not file_does_not_exist'
  '';

  meta = with stdenv.lib; {
    description = "Automatically find diff lines that need test coverage";
    homepage = https://github.com/Bachmann1234/diff-cover;
    license = licenses.asl20;
    maintainers = with maintainers; [ dzabraev ];
  };
}
