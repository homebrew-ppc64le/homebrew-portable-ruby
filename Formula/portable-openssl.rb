require File.expand_path("../Abstract/portable-formula", __dir__)

class PortableOpenssl < PortableFormula
  desc "SSL/TLS cryptography library"
  homepage "https://openssl.org/"
  url "https://www.openssl.org/source/openssl-1.1.1f.tar.gz"
  mirror "https://dl.bintray.com/homebrew/mirror/openssl-1.1.1f.tar.gz"
  mirror "https://www.mirrorservice.org/sites/ftp.openssl.org/source/openssl-1.1.1f.tar.gz"
  sha256 "186c6bfe6ecfba7a5b48c47f8a1673d0f3b0e5ba2e25602dd23b629975da3f35"

  depends_on "portable-zlib" => :build if OS.linux?

  resource "cacert" do
    # http://curl.haxx.se/docs/caextract.html
    url "https://curl.haxx.se/ca/cacert-2020-01-01.pem"
    sha256 "adf770dfd574a0d6026bfaa270cb6879b063957177a991d453ff1d302c02081f"
  end

  def openssldir
    libexec/"etc/openssl"
  end

  def arch_args
    if OS.mac?
      ["enable-ec_nistp_64_gcc_128"]
    else
      ["enable-md2"]
    end
  end

  def configure_args
    args = %W[
      -static
      --prefix=#{prefix}
      --openssldir=#{openssldir}
      no-ssl2
      no-ssl3
      no-shared
      enable-cms
    ]

    if OS.mac?
      args << "zlib-dynamic"
    else
      args << "--with-zlib-lib=#{Formula["portable-zlib"].opt_prefix/"lib"}"
      args << "--with-zlib-include=#{Formula["portable-zlib"].opt_prefix/"include"}"
      args << "zlib"
    end

    args
  end

  def install
    # Load zlib from an explicit path instead of relying on dyld's fallback
    # path, which is empty in a SIP context. This patch will be unnecessary
    # when we begin building openssl with no-comp to disable TLS compression.
    # https://langui.sh/2015/11/27/sip-and-dlopen
    if OS.mac?
      inreplace "crypto/comp/c_zlib.c",
                'zlib_dso = DSO_load(NULL, LIBZ, NULL, 0);',
                'zlib_dso = DSO_load(NULL, "/usr/lib/libz.dylib", NULL, DSO_FLAG_NO_NAME_TRANSLATION);'
    end

    ENV.deparallelize
    system "./config", *(configure_args + arch_args)
    system "make"
    system "make", "test"

    system "make", "install", "MANDIR=#{man}"
    rm_rf man

    if OS.linux?
      # Since we build openssl which statically links to zlib on Linux,
      # any program links to the openssl will have to link to zlib as well.
      inreplace Dir["#{lib}/pkgconfig/lib*.pc"],
        /(Libs: .*)/, "\\1 -L#{Formula["portable-zlib"].opt_prefix/"lib"} -lz"
    end

    cacert = resource("cacert")
    filename = Pathname.new(cacert.url).basename
    openssldir.install cacert.files(filename => "cert.pem")
  end

  test do
    cp_r Dir["#{prefix}/*"], testpath
    input = "x\x9CK\xCB\xCF\a\x00\x02\x82\x01E"
    assert_equal "foo", pipe_output("#{testpath}/bin/openssl zlib -d", input)
  end
end
