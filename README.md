Parcel - A gift of a game framework
================

This is a micro framework which can be used in conjunction with the [DOME engine](https://domeengine.com) to 
make simulation-based games in Wren.

DOME v1.8.0 and above is required for Parcel 2.0

> Warning: This framework is an undocumented work in progress, but iterations of it have already been used in different jam projects.

It provides core classes for a World, made of up Zones (with an associated map), which contains a collection of entities.

Entities declare their actions, represented by discrete Action classes, which the engine then executes to modify the world state.

Parcel also keeps a strict seperation between the UI and the world "model", which allows for greater flexibility.


Acknowledgements
-----------------------------------

The core architecture was proposed in [this article](https://journal.stuffwithstuff.com/2014/07/15/a-turn-based-game-loop/) by [Bob Nystrom](https://github.com/munificent/) before it was adapted for DOME by [Aviv Beeri](https://github.com/avivbeeri).


