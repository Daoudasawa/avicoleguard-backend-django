from rest_framework import viewsets
from rest_framework.permissions import IsAuthenticated
from .models import Observation
from .serializers import ObservationSerializer, ObservationCreateSerializer
from .permissions import IsFlockOwner
from .services import record_observation

class ObservationViewSet(viewsets.ModelViewSet):
    permission_classes = [IsAuthenticated, IsFlockOwner]

    def get_queryset(self):
        flock_id = self.kwargs.get("flock_pk")
        return Observation.active.filter(flock_id=flock_id)

    def get_serializer_class(self):
        if self.action == "create":
            return ObservationCreateSerializer
        return ObservationSerializer

    def perform_create(self, serializer):
        record_observation(
            flock_id=self.kwargs["flock_pk"], 
            data=serializer.validated_data
        )
