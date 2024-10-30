TARGET=${TARGET_ARCH}${TARGET_VENDOR:-}-${TARGET_OS}
host_arch=x86_64
host_os="$TRAVIS_OS_NAME"
case "$host_os" in
  linux)
    host_vendor=-unknown
    host_os=linux-gnu
    ;;
  osx)
    host_vendor=-apple
    host_os=darwin
    ;;
esac
host=${host_arch}${host_vendor:-}-${host_os}
PROJECT_NAME="$PROJECT_BASE/${TARGET}/${TRAVIS_RUST_VERSION}"

remove_relative() {
	local o=
	local oifs="$IFS"
	local v="$1"
	IFS=":"
	for i in $v; do
		case "$i" in
		/*) o="$o:$i" ;;
		'~'/*) o="$o:${HOME}${i##'~'}"
		esac
	done
	
	case "$o" in
	:*) o=${o##:} ;;
	esac

	IFS="$oifs"
	echo "$o"
}

set +x
echo "Old PATH=$PATH"
export PATH=$(remove_relative "$PATH")
echo "New PATH=$PATH"
set -x

: ${DIRS:=.}

run_cargo() {
  for d in ${DIRS}; do
	  (
	  cd "$d"
	  if [ -n "${FEATURES:-}" ]; then
	    cargo "$@" --verbose --target="$TARGET" --features="$FEATURES"
	  else
	    cargo "$@" --verbose --target="$TARGET"
	  fi
	  )
  done
}

export TARGET_CC=cc
RUN_COMPAT=true
CROSS=false
if [ "$host" != "$TARGET" ]; then
  CROSS=true
  RUN_COMPAT=false
  # if the arch is the same, attempt to use the host compiler.
  # FIXME: not always correct to do so
  # Also try to use the host compiler if the arch has a 32vs64 bit differenct
  # FIXME: might also need to check that OS has a reasonable match
  if [ "$TARGET_ARCH" = arm ]; then
    export TARGET_CC="${TARGET_ARCH}-${TARGET_OS}-gcc"
  elif [ "$host_arch" != "$TARGET_ARCH" ] && \
    ! ( [ "$host_arch" == x86_64 ] && [ "$TARGET_ARCH" == i686 ] ); then
    export TARGET_CC=$TARGET-gcc
  fi

  if [ "$host_arch" == x86_64 ] && [ "$TARGET_ARCH" == i686 ]; then
    RUN_COMPAT=true
  fi

  if [ "$TARGET_OS" == linux-musl ]; then
    RUN_COMPAT=true
    export TARGET_CC=musl-gcc
  fi

  if [ "$host_os" = "osx" ]; then
    brew install gnu-sed --default-names
  fi

  # NOTE Workaround for rust-lang/rust#31907 - disable doc tests when cross compiling
  find src -name '*.rs' -type f -exec sed -i -e 's:\(//.\s*```\):\1 ignore,:g' \{\} \;
fi
