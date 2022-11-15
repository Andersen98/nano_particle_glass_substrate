import meep as mp
from .materials import Au_visible
def gold_box_on_glass_substrate(particle_x,particle_y,particle_z, simulation_x,simulation_y,simulation_z):
    """
    Returns a gold box on substrate with specified dimensions.
    The substrate covers everything with x<0.
    The gold nano particle is centered such that its bottom is at z=0.
    """
    assert(particle_x>0 and particle_y>0 and particle_z>0)
    assert(simulation_x>0 and simulation_y>0 and simulation_z>0)

    #define particle
    particle_center = mp.Vector3(0,0,0.5*particle_z)
    particle_size = mp.Vector3(particle_x,particle_y,particle_z)
    particle = mp.Block(center=particle_center, size=particle_size,material=Au_visible)

    #define substrate
    glass = mp.Medium(index=1.5)
    substrate_z = 0.5*simulation_z + .5
    substrate_center = mp.Vector3(0,0,-0.5*substrate_z)
    substrate_size = mp.Vector3(mp.inf,mp.inf,substrate_z)
    substrate = mp.Block(center=substrate_center,size=substrate_size,material=glass)

    return [substrate,particle]




