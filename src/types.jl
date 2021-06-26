# Types

export
    Interaction,
    GeneralInteraction,
    SpecificInteraction,
    AbstractCutoff,
    Simulator,
    Thermostat,
    NeighborFinder,
    Logger,
    Atom,
    AtomMin,
    Simulation

const DefaultFloat = Float64

"An interaction between atoms that contributes to forces on the atoms."
abstract type Interaction end

"""
A general interaction that will apply to all atom pairs.
Custom general interactions should sub-type this type.
"""
abstract type GeneralInteraction <: Interaction end

"""
A specific interaction between sets of specific atoms, e.g. a bond angle.
Custom specific interactions should sub-type this type.
"""
abstract type SpecificInteraction <: Interaction end

"""
A general type of cutoff encoding the approximation used for a potential.
Interactions can be parametrized by the cutoff behavior.
"""
abstract type AbstractCutoff end

"""
A type of simulation to run, e.g. leap-frog integration or energy minimisation.
Custom simulators should sub-type this type.
"""
abstract type Simulator end

"""
A way to keep the temperature of a simulation constant.
Custom thermostats should sub-type this type.
"""
abstract type Thermostat end

"""
A way to find near atoms to save on simulation time.
Custom neighbor finders should sub-type this type.
"""
abstract type NeighborFinder end

"""
A way to record a property, e.g. the temperature, throughout a simulation.
Custom loggers should sub-type this type.
"""
abstract type Logger end

"""
    Atom(; <keyword arguments>)

An atom and its associated information.
Properties unused in the simulation or in analysis can be left with their
default values.
This type cannot be used on the GPU as it is not `isbits` - use `AtomMin` instead.

# Arguments
- `attype::AbstractString=""`: the type of the atom.
- `name::AbstractString=""`: the name of the atom.
- `resnum::Integer=0`: the residue number if the atom is part of a polymer.
- `resname::AbstractString=""`: the residue name if the atom is part of a
    polymer.
- `charge::C=0.0`: the charge of the atom, used for electrostatic interactions.
- `mass::M=0.0`: the mass of the atom.
- `σ::S=0.0`: the Lennard-Jones finite distance at which the inter-particle
    potential is zero.
- `ϵ::E=0.0`: the Lennard-Jones depth of the potential well.
"""
struct Atom{C, M, S, E}
    attype::String
    name::String
    resnum::Int
    resname::String
    charge::C
    mass::M
    σ::S
    ϵ::E
end

# We define constructors rather than using Base.@kwdef as it makes conversion
#   more convenient with the parametric type
function Atom(;
                attype="",
                name="",
                resnum=0,
                resname="",
                charge=0.0,
                mass=0.0,
                σ=0.0,
                ϵ=0.0)
    return Atom(attype, name, resnum, resname, charge, mass, σ, ϵ)
end

function Base.show(io::IO, a::Atom)
    print(io, "Atom with name \"", a.name, "\", type \"", a.attype, "\", charge=", a.charge,
            ", mass=", a.mass, ", σ=", a.σ, ", ϵ=", a.ϵ)
end

"""
    AtomMin(; <keyword arguments>)

An atom and minimal information required for simulation.
Properties unused in the simulation or in analysis can be left with their
default values.
This type is `isbits` and can be used on the GPU - use `Atom` in other contexts to store
more information.

# Arguments
- `charge::C=0.0`: the charge of the atom, used for electrostatic interactions.
- `mass::M=0.0`: the mass of the atom.
- `σ::S=0.0`: the Lennard-Jones finite distance at which the inter-particle
    potential is zero.
- `ϵ::E=0.0`: the Lennard-Jones depth of the potential well.
"""
struct AtomMin{C, M, S, E}
    charge::C
    mass::M
    σ::S
    ϵ::E
end

function AtomMin(;
                charge=0.0,
                mass=0.0,
                σ=0.0,
                ϵ=0.0)
    return AtomMin(charge, mass, σ, ϵ)
end

function Base.show(io::IO, a::AtomMin)
    print(io, "AtomMin with charge=", a.charge, ", mass=", a.mass, ", σ=", a.σ, ", ϵ=", a.ϵ)
end

"""
    Simulation(; <keyword arguments>)

The data needed to define and run a molecular simulation.
Properties unused in the simulation or in analysis can be left with their
default values.

# Arguments
- `simulator::Simulator`: the type of simulation to run.
- `atoms::A`: the atoms, or atom equivalents, in the simulation. Can be
    of any type.
- `specific_inter_lists::SI=()`: the specific interactions in the simulation,
    i.e. interactions between specific atoms such as bonds or angles. Typically
    a `Tuple`.
- `general_inters::GI=()`: the general interactions in the simulation, i.e.
    interactions between all or most atoms such as electrostatics. Typically a
    `Tuple`.
- `coords::C`: the coordinates of the atoms in the simulation. Typically a
    `Vector` of `SVector`s of any dimension and type `T`, where `T` is an
    `AbstractFloat` type.
- `velocities::V=zero(coords)`: the velocities of the atoms in the simulation,
    which should be the same type as the coordinates. The meaning of the
    velocities depends on the simulator used, e.g. for the `VelocityFreeVerlet`
    simulator they represent the previous step coordinates for the first step.
- `temperature::T=0.0`: the temperature of the simulation.
- `box_size::B`: the size of the cube in which the simulation takes place.
- `neighbor_finder::NeighborFinder=NoNeighborFinder()`: the neighbor finder
    used to find close atoms and save on computation.
- `thermostat::Thermostat=NoThermostat()`: the thermostat which applies during
    the simulation.
- `loggers::Dict{String, <:Logger}=Dict()`: the loggers that record properties
    of interest during the simulation.
- `timestep::S=0.0`: the timestep of the simulation.
- `n_steps::Integer=0`: the number of steps in the simulation.
- `gpu_diff_safe::Bool`: whether to use the GPU implementation. Defaults to
    `isa(coords, CuArray)`.
"""
struct Simulation{D, T, A, C, V, GI, SI, B, S, F, E}
    simulator::Simulator
    atoms::A
    specific_inter_lists::SI
    general_inters::GI
    coords::C
    velocities::V
    temperature::T
    box_size::B
    neighbors::Vector{Tuple{Int, Int}}
    neighbor_finder::NeighborFinder
    thermostat::Thermostat
    loggers::Dict{String, <:Logger}
    timestep::S
    n_steps::Int
    n_steps_made::Vector{Int}
    force_units::F
    energy_units::E
end

Simulation{D}(args...) where {D, T, A, C, V, GI, SI, B, S, F, E} = Simulation{D, T, A, C, V, GI, SI, B, S, F, E}(args...)

forceunits(inter::Interaction) = inter.force_units
energyunits(inter::Interaction) = inter.energy_units

function Simulation(;
                    simulator=VelocityVerlet(),
                    atoms,
                    specific_inter_lists=(),
                    general_inters=(),
                    coords,
                    velocities=zero(coords),
                    temperature=0.0,
                    box_size,
                    neighbors=Tuple{Int, Int}[],
                    neighbor_finder=NoNeighborFinder(),
                    thermostat=NoThermostat(),
                    loggers=Dict{String, Logger}(),
                    timestep=0.0,
                    n_steps=0,
                    n_steps_made=[0],
                    gpu_diff_safe=isa(coords, CuArray))
    if length(general_inters) == 0 && length(specific_inter_lists) == 0
        error("Either general interactions or specific interactions must be provided")
    end

    force_unit_list = [forceunits.(general_inters)...]
    for inter in specific_inter_lists
        append!(force_unit_list, forceunits.(inter))
    end
    if length(Set(force_unit_list)) > 1
        error("More than one force unit found in interactions: ", join(Set(force_unit_list), ", "))
    end
    force_units = first(force_unit_list)

    energy_unit_list = [energyunits.(general_inters)...]
    for inter in specific_inter_lists
        append!(energy_unit_list, energyunits.(inter))
    end
    if length(Set(energy_unit_list)) > 1
        error("More than one energy unit found in interactions: ", join(Set(energy_unit_list), ", "))
    end
    energy_units = first(energy_unit_list)

    T = typeof(temperature)
    A = typeof(atoms)
    C = typeof(coords)
    V = typeof(velocities)
    GI = typeof(general_inters)
    SI = typeof(specific_inter_lists)
    B = typeof(box_size)
    S = typeof(timestep)
    F = typeof(force_units)
    E = typeof(energy_units)
    return Simulation{gpu_diff_safe, T, A, C, V, GI, SI, B, S, F, E}(
                simulator, atoms, specific_inter_lists, general_inters, coords,
                velocities, temperature, box_size, neighbors, neighbor_finder,
                thermostat, loggers, timestep, n_steps, n_steps_made,
                force_units, energy_units)
end

function Base.show(io::IO, s::Simulation)
    print(io, "Simulation with ", length(s.coords), " atoms, ",
                typeof(s.simulator), " simulator, ", s.timestep, " timestep, ",
                s.n_steps, " steps, ", first(s.n_steps_made), " steps made")
end