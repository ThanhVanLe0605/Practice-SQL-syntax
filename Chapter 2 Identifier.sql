
-- This topic is about identifiers, i.e. syntax rules for names of tables, columns, and other database objects.
-- Where appropriate, the examples should cover variations used by different SQL implementations, or identify the
-- SQL implementation of the example.

-- Section 2.1: Unquoted identifiers

-- Unquoted identifiers can use letters (a-z), digits (0-9), and underscore (_), and must start with a letter.
-- Depending on SQL implementation, and/or database settings, other characters may be allowed, some even as the
-- first character, e.g.
-- MS SQL: @, $, #, and other Unicode letters (source)
-- MySQL: $ (source)
-- Oracle: $, #, and other letters from database character set (source)
-- PostgreSQL: $, and other Unicode letters (source)
-- Unquoted identifiers are case-insensitive. How this is handled depends greatly on SQL implementation:
-- MS SQL: Case-preserving, sensitivity defined by database character set, so can be case-sensitive.
-- MySQL: Case-preserving, sensitivity depends on database setting and underlying file system.
-- Oracle: Converted to uppercase, then handled like quoted identifier.
-- PostgreSQL: Converted to lowercase, then handled like quoted identifier.
-- SQLite: Case-preserving; case insensitivity only for ASCII character 