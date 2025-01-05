model prey_predator


//defines the world agent
global {
	int nb_preys_init <- rnd(200,300);
	float prey_max_energy <- 1.0;		//max allowed energy
	float prey_max_transfer <- 0.1;		//how much energy it gains from eating
	float prey_energy_consum <- 0.05;	//how much energy it loses each cycle
	float prey_proba_reproduce <- 0.01;
    int prey_nb_max_offsprings <- 6; 
    float prey_energy_reproduce <- 0.5;
    float prey_adult_age <- 1.4;
    float prey_death_age <- rnd(12.0, 13.0);
    float prey_hunger_level <- rnd(0.35, 0.5);
	int nb_preys -> {length (prey)};
	
	int nb_predators_init <- rnd(20,30);
    float predator_max_energy <- 1.0;
	float predator_energy_transfer <- 0.5;
	float predator_energy_consum <- 0.02;
	float predator_proba_reproduce <- 0.01;
    int predator_nb_max_offsprings <- 3;
    float predator_adult_age <- 3.0;
    float predator_death_age <- rnd(17.0 , 19.0);
    float predator_energy_reproduce <- 0.5;
    float predator_hunger_level <- rnd(0.7, 0.85);
    int nb_predators -> {length(predator)};
    
    
    
    bool is_batch <- false;
	
	
    
    //save results to a file
    reflex save_result when: (nb_preys = 0) or (nb_predators = 0){
		save ("cycle: "+ cycle + "; nbPreys: " + nb_preys
			+ "; minEnergyPreys: " + (prey min_of each.energy)
			+ "; maxSizePreys: " + (prey max_of each.energy) 
			+ "; minAgePrey: " + (prey min_of each.age)
			+ "; maxAgePrey: " + (prey max_of each.age)
			
	   		+ "; nbPredators: " + nb_predators           
	   		+ "; minEnergyPredators: " + (predator min_of each.energy)          
	   		+ "; maxSizePredators: " + (predator max_of each.energy))
	   		+ "; minAgePredators: " + (predator min_of each.age)
	   		+ "; maxAgePredators: " + (predator max_of each.age)
	   		
	   		to: "results.txt" rewrite: (cycle = 0) ? true : false;
	}
	
	reflex stop_simulation when: (nb_preys = 0) or (nb_predators = 0) and !is_batch {
        do pause ;
    }
	
	file map_init <- image_file("../includes/data/raster_map.png");
	
	init {
    	create prey number: nb_preys_init ;
    	create predator number: nb_predators_init ;
    	create vegetation_cell number: 2000;
	    create water_cell number: 500;
	
	    ask vegetation_cell {
	        color <- rgb(int(255 * (1 - food)), 255, int(255 * (1 - food)));
	    }
	
	    ask water_cell {
	        color <- #blue;
	    }
}

species generic_species {
	float size <- 1.0;
	rgb color;
	float age <- 1.0 update: age + (1/12);	//define and update age at each cycle. 1/12 means 1 cycle = 1 month
	float max_energy;
	float max_transfer;
	float energy_consum;
	cell my_cell <- one_of(cell); // Reference to the parent cell
	float energy <- rnd(max_energy) update: energy - energy_consum max: max_energy;
	float death_age;
	//for reporduction
	float proba_reproduce ;
    int nb_max_offsprings;
    float energy_reproduce;
    float adult_age;
    
    float hunger_level;
    bool hungry <- false;
    
    reflex check_hunger {
    	if (energy < hunger_level){
    		hungry <- true;
    	} else {
    		hungry <- false;
    	}
    }
    
	init {
        location <- my_cell.location;
    }

	reflex basic_move {
		my_cell <- choose_cell();
		location <- my_cell.location;
	}
	vegetation_cell choose_cell {
		return nil;
	}

	reflex eat {
		if(my_cell.is_vegetation){
			energy <- energy + energy_from_eat();	
		}	
	}
	reflex drink {
    	if (my_cell.is_water) {
        	write "Drinking water at " + my_cell.location;
    	}
	}

	reflex die when: energy <= 0 or age > death_age{
		do die;
	}

	float energy_from_eat {
		return 0.0;
	} 

	aspect base {
		draw circle(size) color: color;
	}
	
	reflex aging when: (age > adult_age) {
		energy_consum <- energy_consum + 0.0005;
	}
	reflex reproduce when: (energy >= energy_reproduce) and (flip(proba_reproduce)) and (age > adult_age) {
        int nb_offsprings <- rnd(1, nb_max_offsprings);
        create species(self) number: nb_offsprings {
            my_cell <- myself.my_cell ;
            location <- my_cell.location ;
            energy <- myself.energy / nb_offsprings ;
        }
        energy <- energy / nb_offsprings ;
    }
    aspect info {
		draw square(size) color: color;
		draw string(energy with_precision 2) size: 3 color: #yellow;
	}
}


species prey parent: generic_species {
	rgb color <- #blue;
	float max_energy <- prey_max_energy;
	float max_transfer <- prey_max_transfer;
	float energy_consum <- prey_energy_consum;
	float death_age <- prey_death_age;
	float adult_age <- prey_adult_age;
	//reproduction
	float proba_reproduce <- prey_proba_reproduce ;
    int nb_max_offsprings <- prey_nb_max_offsprings ;
    float energy_reproduce <- prey_energy_reproduce ;
    float hunger_level <- prey_hunger_level;
    
    
	
	float energy_from_eat {
		float energy_transfer <- 0.0;
		if(my_cell.food > 0 and hungry) {
			energy_transfer <- min([max_transfer, my_cell.food]);
			my_cell.food <- my_cell.food - energy_transfer;
		}
		return energy_transfer;
	}
	vegetation_cell choose_cell {
    list<vegetation_cell> safe_cells <- my_cell.neighbors2 where (empty(predator inside (each)));
    list<vegetation_cell> populated_cells <- safe_cells where (!empty(prey inside (each)));
    if (hungry){
    	return (safe_cells) with_max_of (each.food);
    }
    else if (!hungry and (!empty(populated_cells))) {
        return one_of(populated_cells);
    } else {
        return one_of(my_cell.neighbors2); // choose a random cell if no safe cells are found
    }
}
}

species predator parent: generic_species {
	rgb color <- #red;
	float max_energy <- predator_max_energy;
	float energy_transfer <- predator_energy_transfer;
	float energy_consum <- predator_energy_consum;
	float death_age <- predator_death_age;
	float adult_age <- predator_adult_age;
	//reproduction
	float proba_reproduce <- predator_proba_reproduce ;
    int nb_max_offsprings <- predator_nb_max_offsprings ;
    float energy_reproduce <- predator_energy_reproduce ;
    float hunger_level <- predator_hunger_level;
    
    
	float energy_from_eat {
		if (hungry){
			if (age > 3){
			list<prey> reachable_preys <- prey inside (my_cell);	
			if(! empty(reachable_preys)) {
				ask one_of (reachable_preys) {
					do die;
				}
				return energy_transfer;
			}
			
			} else {
				list<predator> reachable_predators <- predator inside (my_cell);
				if(! empty(reachable_predators)) {
					ask one_of (reachable_predators) {
						energy <- energy - 0.01;
					}
					return energy_transfer;
				}
			}
		}		
	}
	vegetation_cell choose_cell { //this shit OP
		vegetation_cell my_cell_tmp <- shuffle(my_cell.neighbors2) first_with (!(empty(prey inside (each))));
		if my_cell_tmp != nil {
			return my_cell_tmp;
		} else {
			return one_of(my_cell.neighbors2);
		}
	}		
}

//defining cells
grid cell width: 50 height: 50 neighbors: 5 {
    bool is_water <- false; // Indicates if the cell is a water cell
    bool is_vegetation <- false; // Indicates if the cell is a vegetation cell
}
species vegetation_cell parent: cell {
    float max_food <- 1.0;
    float food_prod <- rnd(0.01);
    float food <- rnd(1.0) max: max_food update: food + food_prod;
    rgb color <- rgb(int(255 * (1 - food)), 255, int(255 * (1 - food))) update: rgb(int(255 * (1 - food)), 255, int(255 * (1 - food)));

    init {
        is_vegetation <- true; // Mark this cell as vegetation
    }
}
species water_cell parent: cell {
    rgb color <- #blue;

    init {
        is_water <- true; // Mark this cell as water
    }
}



experiment prey_predator type: gui {
	// for prey
	parameter "Initial number of preys: " var: nb_preys_init min: 1 max: 1000 category: "Prey";
	parameter "Prey max energy: " var: prey_max_energy category: "Prey";
	parameter "Prey max transfer: " var: prey_max_transfer  category: "Prey";
	parameter "Prey energy consumption: " var: prey_energy_consum  category: "Prey";
	parameter "Prey probability reproduce: " var: prey_proba_reproduce category: "Prey" ;
	parameter "Prey nb max offsprings: " var: prey_nb_max_offsprings category: "Prey" ;
	parameter "Prey energy reproduce: " var: prey_energy_reproduce category: "Prey" ;
	// for predator
	parameter "Initial number of predators: " var: nb_predators_init min: 0 max: 200 category: "Predator" ;
	parameter "Predator max energy: " var: predator_max_energy category: "Predator" ;
	parameter "Predator energy transfer: " var: predator_energy_transfer  category: "Predator" ;
	parameter "Predator energy consumption: " var: predator_energy_consum  category: "Predator" ;
	parameter "Predator probability reproduce: " var: predator_proba_reproduce category: "Predator" ;
	parameter "Predator nb max offsprings: " var: predator_nb_max_offsprings category: "Predator" ;
	parameter "Predator energy reproduce: " var: predator_energy_reproduce category: "Predator" ;
		
	int nb_predators_init <- 20;
    float predator_max_energy <- 1.0;
    float predator_energy_transfer <- 0.5;
    float predator_energy_consum <- 0.02;
    
	output {
		/*display main_display {
			grid vegetation_cell border: #black;
			species prey aspect: base;		//render/output the spercies on screen
			species predator aspect: base;
		}
		*/
		display info_display type:2d antialias:false {
			grid cell border: #black;
			species prey aspect: info;
			species predator aspect: info;
		}
		
		display Population_information refresh: every(5#cycles)  type: 2d {
			chart "Species evolution" type: series size: {1,0.5} position: {0, 0} {
				data "number_of_preys" value: nb_preys color: #blue;
				data "number_of_predator" value: nb_predators color: #red;
			}
			chart "Prey Energy Distribution" type: histogram background: #lightgray size: {0.5,0.5} position: {0, 0.5} {
				data "]0;0.25]" value: prey count (each.energy <= 0.25) color:#blue;
				data "]0.25;0.5]" value: prey count ((each.energy > 0.25) and (each.energy <= 0.5)) color:#blue;
				data "]0.5;0.75]" value: prey count ((each.energy > 0.5) and (each.energy <= 0.75)) color:#blue;
				data "]0.75;1]" value: prey count (each.energy > 0.75) color:#blue;
			}
			chart "Predator Energy Distribution" type: histogram background: #lightgray size: {0.5,0.5} position: {0.5, 0.5} {
				data "]0;0.25]" value: predator count (each.energy <= 0.25) color: #red;
				data "]0.25;0.5]" value: predator count ((each.energy > 0.25) and (each.energy <= 0.5)) color: #red;
				data "]0.5;0.75]" value: predator count ((each.energy > 0.5) and (each.energy <= 0.75)) color: #red;
				data "]0.75;1]" value: predator count (each.energy > 0.75) color: #red;
			}
		}
		
		monitor "Number of preys" value: nb_preys;
		monitor "Number of predators" value: nb_predators;
	}
	
}
