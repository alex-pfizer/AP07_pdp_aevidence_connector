## Dummy script for docker executable
print("Hello MSstats")
## if this works, the docker container should print whatever is contained in ./pdp_input/software.txt
print(
  readChar("usr/local/src/pdp_input/software.txt", nchars=file.info("./pdp_input/software.txt")$size)
)