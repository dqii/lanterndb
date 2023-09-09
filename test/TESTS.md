# Lanterndb Test Suite

This document provides an overview of the test suite for the Lanterndb PostgreSQL vector database extension. It outlines the purpose of each test file and any dependencies between them.

## Test Files

### test1.sql

This test checks the basic functionality of the Lanterndb extension. It tests the creation of a vector and the basic operations that can be performed on it.

### test2.sql

This test checks the advanced functionality of the Lanterndb extension. It tests the more complex operations that can be performed on a vector. This test depends on `test1.sql` as it assumes that the basic functionality is working correctly.

### test3.sql

This test checks the error handling of the Lanterndb extension. It tests how the extension handles invalid input and unexpected situations. This test does not have any dependencies.

## Dependencies

The `test2.sql` file depends on `test1.sql`. The tests in `test2.sql` assume that the basic functionality tested in `test1.sql` is working correctly. Therefore, `test1.sql` should be run before `test2.sql`.

The `test3.sql` file does not have any dependencies and can be run at any time.
