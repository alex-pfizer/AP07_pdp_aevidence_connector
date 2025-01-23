## Dummy script for docker executable
print("Hello MSstats")
## if this works, the docker container should print whatever is contained in ./pdp_input/software.txt
list.files("/usr/local/src/pdp_input")
# print(
#   readChar("./software.txt", nchars=file.info("./software.txt")$size)
# )