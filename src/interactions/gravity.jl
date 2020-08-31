"""
    Gravity(nl_only, G)

The gravitational interaction.
"""
struct Gravity{T} <: GeneralInteraction
    nl_only::Bool
    G::T
end

@inline @inbounds function force(inter::Gravity,
                                    coord_i,
                                    coord_j,
                                    atom_i,
                                    atom_j,
                                    box_size)
    dr = vector(coord_i, coord_j, box_size)
    r2 = sum(abs2, dr)

    mi, mj = atom_i.mass, atom_j.mass
    params = (inter.G, mi, mj)

    f = force_nocutoff(inter, r2, inv(r2), params)
    return f * dr
end

@fastmath function force_nocutoff(::Gravity, r2, invr2, (G, mi, mj))
    (G * mi * mj) / √(r2 ^ 3)
end

@inline @inbounds function potential_energy(inter::Gravity,
                                    s::Simulation,
                                    i::Integer,
                                    j::Integer)
    U = eltype(s.coords[i]) # this is not Unitful compatible
    i == j && return zero(U)

    dr = vector(s.coords[i], s.coords[j], s.box_size)
    r2 = sum(abs2, dr)

    mi, mj = s.atoms[i].mass, s.atoms[j].mass
    params = (inter.G, mi, mj)

    potential(inter, r2, inv(r2), params)
end


@fastmath function potential(::Gravity, r2, invr2, (G, mi, mj))
    (G * mi * mj) * √invr2
end
