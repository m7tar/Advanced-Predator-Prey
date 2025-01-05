# Advanced-Predator-Prey
This repository contains an enhanced predator-prey simulation model implemented using the GAMA platform. The project builds upon traditional models by introducing advanced features to improve ecological realism and agent adaptability. It serves as a tool for studying complex predator-prey dynamics, emergent behaviors, and the impact of environmental factors on species survival.

## Features

* Environmental Heterogeneity:
  * Spatial variation using raster-based environmental data.
  * Refuge zones where prey can seek safety from predators.
  * Dynamic food regeneration in vegetation cells.

* Adaptive Agent Behaviors:
  * Prey prioritize food or refuge based on hunger and predator proximity.
  * Predators optimize hunting strategies based on prey distribution.
  * Energy-based thresholds for hunger, reproduction, and survival.
* Visualization Tools:
  * 2D displays for population distribution.
  * Charts showing population dynamics over time.
  * Energy distribution histograms for both prey and predators.

## Key Components
* Species Module:
  * Generic species class extended by prey and predator agents.
  * Lifecycle features including age, energy dynamics, and reproduction.

* Environment Module:
  * Grid-based environment with food distribution and refuge zones.
  * Interaction between agents and the environment to simulate real-world ecological patterns.

## Usage
1. Download and install Gama 
2. Create a project using Gama
3. Clone the repo inside the project folder inside the newly created project directory.
4. Run the simulation and explore.
