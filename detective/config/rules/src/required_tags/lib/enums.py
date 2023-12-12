from enum import Enum

class LayerOptions(Enum):
    BASE = 1
    LATEST = 2
    ALL_VERSIONS = 3

class ComplianceStates(Enum):
    COMPLIANT = "COMPLIANT"
    NON_COMPLIANT = "NON_COMPLIANT"
    NOT_APPLICABLE = "NOT_APPLICABLE"
