#!/usr/sbin/dtrace -s
/*
 * Name:		counter.d
 * Author:		FOXX (frozenfoxx@github.com)
 * Date:		02/13/2009
 * Description:		This program creates a counter.  It ticks every second and increments
 * 			a counter of the number of seconds the program has run.  When it receives 
 *			a terminate signal from DTrace it outputs the total seconds run.
 */

dtrace:::BEGIN
{
  /* Set the counter */
  i = 0;
}

profile:::tick-1sec
{
  i = i + 1;
  trace(i);
  /* This could also be done as trace(++i); */
}

dtrace:::END
{
  /* Output the count */
  trace(i);
}
