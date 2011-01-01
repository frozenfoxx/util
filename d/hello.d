#!/usr/sbin/dtrace -s
/* 
 * Name:		hello.d
 * Date:		02/12/2009
 * Author:		FOXX (frozenfoxx@github.com)
 * Description:		A simple, "Hello, World," program for DTrace.
*/

dtrace:::BEGIN
{
	trace("hello, world");
	exit(0);
}
