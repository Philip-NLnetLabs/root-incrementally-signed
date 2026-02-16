This demonstrates how the DNS root zone can be signed incrementally.

The doit.sh script signs the root zone twice a day for the month of
February 2026.

The script depends on a particular version Rust dnst crate.

Check out the dnst sources with
```
git clone https://github.com/NLnetLabs/dnst.git
```
Check out the branch signer-incremental-faketime (currently commit
c4224b3256895018c27f8d602bb5805ae7dd58ae):
```
cd dnst
git checkout signer-incremental-faketime
```
Install the dnst binary with
```
cargo install --path .
```

The output is a series of files with the pattern root.signed-<unixtime>

Changes between two versions are easy to see using the following command:
```
diff -u <(sort root.signed-1772020800) <(sort root.signed-1772064000)
```
