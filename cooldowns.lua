cooldowns = {
    ['������ ���������� �����'] = true,
    ['������� ����� ����������'] = true,
    ['�������� �������� ����'] = true,
    ['��������� ����'] = true,

    ['BARD'] = {
        ['����������� ������'] = {
            ['������ ���������'] = {
                calculate = 'n * 0.86'
            },
        },
        ['����'] = true,
        ['��� �����'] = true,
        ['������ �������'] = true,
    },

    ['NECROMANCER'] = {
        ['��� �����'] = true,
        ['����� ����'] = true,
    },

    ['STALKER'] = {
        ['�������'] = {
            ['������ ���������'] = {
                calculate = 'n * 2'
            },
        },
        ['������ ������'] = true,
        ['��������'] = true,
    },

    ['WARLOCK'] = {
        ['����� ���������'] = true,
        ['������������'] = true,
        ['������ �������'] = true,
        ['������ ����'] = true,
        ['�������'] = true,
        ['������ ����'] = true,
        ['���������� ����'] = true,
        ['���������� ����'] = { -- �������, ��� ������ ����� ����
            rank_1 = 360,
            rank_2 = 310,
            rank_3 = 260,
        },
    },

    ['DRUID'] = {
        ['��������� ����'] = {
            ['������ ���������'] = {
                resetCooldowns = {
                    '������� ����',
                }
            },
        },
        ['������� ����'] = true,
        ['�������� �����'] = true,
        ['������ �����'] = true,
    },

    ['ENGINEER'] = {
        ['�������� �������'] = {
            calculate = 'n * 0.86'
        },
        ['������������'] = {
            calculate = 'n * 0.75'
        },
        ['������� ����'] = {
            calculate = 'n * 0.75'
        },
    },

    ['MAGE'] = {
        ['���������� ������'] = {
            calculate = 'n * 0.86'
        },
        ['���������� �����'] = true,
        ['������� ��������'] = true,
    },

    ['PALADIN'] = {
        ['�����������'] = {
            ['������ ���������'] = {
                calculate = 'n * 4'
            }
        },
        ['��������'] = true,
        ['������ �����'] = true,
    },

    ['PRIEST'] = {
        ['����������'] = true,
        ['������'] = true,
        ['����� �����'] = true,
        ['����������� �����'] = true,
        ['������'] = true,
        ['����� ��������'] = {
            rank_1 = 390,
            rank_2 = 330,
            rank_3 = 270,
        },
        ['������'] = 180,
    },

    ['PSIONIC'] = {
        ['���������� �����'] = true,
        ['�������'] = true,
        ['������������ �������'] = true,
        ['����� �������'] = 96,
    },

    ['WARRIOR'] = {
        ['��������'] = true,
        ['������ ����������'] = true,
        ['������ �������'] = true,
    },
}
