{ stdenv, fetchFromGitHub, mercurial, makeWrapper,
  asciidoc, xmlto, docbook_xsl, docbook_xml_dtd_45, libxslt, libxml2
}:

stdenv.mkDerivation rec {
  version = "1.0.0";
  pname = "git-remote-hg";

  src = fetchFromGitHub {
    owner = "mnauw";
    repo = "git-remote-hg";
    rev = "v${version}";
    sha256 = "0anl054zdi5rg5m4bm1n763kbdjkpdws3c89c8w8m5gq1ifsbd4d";
  };

  buildInputs = [ mercurial.python mercurial makeWrapper
    asciidoc xmlto docbook_xsl docbook_xml_dtd_45 libxslt libxml2
  ];

  doCheck = false;

  installFlags = "HOME=\${out} install-doc";

  postInstall = ''
    wrapProgram $out/bin/git-remote-hg \
      --prefix PYTHONPATH : "$(echo ${mercurial}/lib/python*/site-packages):$(echo ${mercurial.python}/lib/python*/site-packages)${stdenv.lib.concatMapStrings (x: ":$(echo ${x}/lib/python*/site-packages)") mercurial.pythonPackages or []}"
  '';

  meta = with stdenv.lib; {
    homepage = https://github.com/mnauw/git-remote-hg;
    description = "Git remote helper for Mercurial repositories";
    license = licenses.gpl2;
    maintainers = [ maintainers.garbas ];
    platforms = platforms.unix;
  };
}
