## Dummy script for docker executable
print("Hello MSstats")
## if this works, the docker container should print whatever is contained in ./pdp_input/software.txt
print(list.files("/usr/local/src/pdp_input"))
print(list.files())



# print(
#   readChar("./software.txt", nchars=file.info("./software.txt")$size)
# )