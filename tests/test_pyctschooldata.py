"""
Tests for pyctschooldata Python wrapper.

Minimal smoke tests - the actual data logic is tested by R testthat.
These just verify the Python wrapper imports and exposes expected functions.
"""

import pytest


def test_import_package():
    """Package imports successfully."""
    import pyctschooldata
    assert pyctschooldata is not None


def test_has_fetch_enr():
    """fetch_enr function is available."""
    import pyctschooldata
    assert hasattr(pyctschooldata, 'fetch_enr')
    assert callable(pyctschooldata.fetch_enr)


def test_has_get_available_years():
    """get_available_years function is available."""
    import pyctschooldata
    assert hasattr(pyctschooldata, 'get_available_years')
    assert callable(pyctschooldata.get_available_years)


def test_has_version():
    """Package has a version string."""
    import pyctschooldata
    assert hasattr(pyctschooldata, '__version__')
    assert isinstance(pyctschooldata.__version__, str)
